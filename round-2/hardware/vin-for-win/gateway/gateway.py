#!/usr/bin/env python3

import socket
import threading
import json
import time
import logging
from collections import defaultdict

class CANMessage:
    def __init__(self, can_id, data, timestamp=None):
        self.can_id = can_id
        if isinstance(data, bytes) and len(data) > 8:
            raise ValueError(f"CAN data too long: {len(data)} bytes (max 8)")
        self.data = data
        self.timestamp = timestamp or time.time()

    def to_dict(self):
        return {
            'can_id': self.can_id,
            'data': self.data.hex() if isinstance(self.data, bytes) else self.data,
            'timestamp': self.timestamp
        }

class SimpleCANBroker:
    def __init__(self, host='0.0.0.0', port=9999):
        self.host = host
        self.port = port
        self.sessions = {}
        self.message_queues = defaultdict(list)
        self.running = False

        # VIN 서비스 통합
        self.vehicle_vin = "ECTF{G3T_V1N_BR0}"  # 17자리 VIN
        self.isotp_sessions = {}  # ISO-TP 세션 관리

        self.setup_logging()

    def setup_logging(self):
        log_format = '%(asctime)s [%(levelname)s] %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler('/tmp/can_broker.log')
            ]
        )
        self.logger = logging.getLogger('SimpleCANBroker')
        self.logger.info("Simple CAN Broker with integrated VIN service initialized")

    def start(self):
        self.running = True
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        try:
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(10)
            self.logger.info(f"Simple CAN Broker started on {self.host}:{self.port}")

            while self.running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    self.logger.info(f"New connection from {addr}")

                    thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, addr),
                        daemon=True
                    )
                    thread.start()

                except Exception as e:
                    if self.running:
                        self.logger.error(f"Error accepting connection: {e}")

        except Exception as e:
            self.logger.error(f"Failed to start Simple CAN Broker: {e}")
            raise

    def handle_client(self, client_socket, addr):
        session_id = None
        client_type = None

        try:
            client_socket.settimeout(3600)

            data = client_socket.recv(1024).decode()
            if not data:
                self.logger.warning(f"Empty handshake from {addr}")
                return

            handshake = json.loads(data)
            session_id = handshake['session_id']
            client_type = handshake['type']

            self.logger.info(f"Handshake: session={session_id}, type={client_type}, addr={addr}")

            if session_id in self.sessions:
                self.logger.warning(f"Replacing existing session {session_id}")
                old_socket = self.sessions[session_id]['socket']
                try:
                    old_socket.close()
                except:
                    pass

            self.sessions[session_id] = {
                'socket': client_socket,
                'type': client_type,
                'addr': addr,
                'connected_at': time.time(),
                'last_activity': time.time(),
                'message_count': 0
            }


            response = {'status': 'connected', 'session_id': session_id}
            client_socket.send(json.dumps(response).encode() + b'\n')

            self.logger.info(f"Session {session_id} ({client_type}) connected from {addr}")

            buffer = ""
            while self.running:
                try:
                    data = client_socket.recv(1024).decode()
                    if not data:
                        self.logger.info(f"Client {session_id} disconnected")
                        break

                    self.sessions[session_id]['last_activity'] = time.time()
                    buffer += data

                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        if line.strip():
                            self.sessions[session_id]['message_count'] += 1
                            self.process_message(session_id, line.strip())

                except socket.timeout:
                    self.logger.warning(f"1-hour timeout for session {session_id}")
                    break
                except Exception as e:
                    self.logger.error(f"Error receiving from {session_id}: {e}")
                    break

        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid handshake JSON from {addr}: {e}")
        except Exception as e:
            self.logger.error(f"Error handling client {addr}: {e}")
        finally:
            if session_id:
                if session_id in self.sessions:
                    del self.sessions[session_id]
            client_socket.close()

    def process_message(self, session_id, message):
        try:
            msg_data = json.loads(message)
            msg_type = msg_data.get('type', 'unknown')

            if msg_type == 'send':
                can_data = bytes.fromhex(msg_data['data'])

                if len(can_data) > 8:
                    self.logger.error(f"[{session_id}] CAN data too long: {len(can_data)} bytes")
                    return

                can_msg = CANMessage(
                    can_id=msg_data['can_id'],
                    data=can_data
                )

                self.logger.info(f"CAN from {session_id}: ID=0x{can_msg.can_id:03X}, Data={can_msg.data.hex()} ({len(can_msg.data)} bytes)")
                self.route_message(session_id, can_msg)

            elif msg_type == 'dump_start':
                self.logger.info(f"Starting candump for {session_id}")
                self.send_queued_messages(session_id)

        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid JSON from {session_id}: {e}")
        except Exception as e:
            self.logger.error(f"Error processing message from {session_id}: {e}")

    def route_message(self, sender_session, can_msg):
        """메시지 라우팅 - VIN 요청은 직접 처리"""
        sender_info = self.sessions.get(sender_session)
        if not sender_info:
            return

        sender_type = sender_info['type']

        # VIN 요청(0x7DF)은 직접 처리
        if sender_type == 'infotainment' and can_msg.can_id == 0x7DF:
            self.handle_vin_request_direct(sender_session, can_msg)

    def handle_vin_request_direct(self, session_id, can_msg):
        """VIN 요청을 직접 처리 (별도 engine 컨테이너 없이)"""
        self.logger.info(f"[{session_id}] Processing VIN request directly: ID=0x{can_msg.can_id:03X}, Data={can_msg.data.hex()}")

        # UDS 메시지 처리
        response = self.handle_uds_message(session_id, can_msg.can_id, can_msg.data)
        if response:
            # 직접 응답 전송
            response_msg = CANMessage(can_id=response['can_id'], data=response['data'])
            self.send_to_session(session_id, response_msg)
            self.logger.info(f"[{session_id}] VIN response sent: ID=0x{response['can_id']:03X}, Data={response['data'].hex()}")

    def handle_uds_message(self, session_id, can_id, data):
        """VIN 요청과 Flow Control 처리"""
        if can_id != 0x7DF:  # UDS 기능 주소
            return None

        if len(data) < 1:
            return None

        # ISO-TP 프레이밍 확인
        first_byte = data[0]

        # Flow Control Frame 처리 (0x3X)
        if (first_byte & 0xF0) == 0x30:
            return self.handle_flow_control(session_id, data)

        # Single Frame 처리 (0x0X)
        if (first_byte & 0xF0) == 0x00:
            if len(data) < 2:
                return None

            service_id = data[1]
            self.logger.info(f"Processing UDS service 0x{service_id:02X} for session {session_id}")

            # VIN 요청만 처리 (Service 0x09, PID 0x02)
            if service_id == 0x09 and len(data) >= 3 and data[2] == 0x02:
                return self.handle_vin_request(session_id)
            else:
                # 다른 모든 서비스는 지원하지 않음
                return {
                    'can_id': 0x7E8,  # UDS 응답 CAN ID
                    'data': bytes([0x03, 0x7F, service_id, 0x11, 0x00, 0x00, 0x00, 0x00])  # Service not supported
                }

        return None

    def handle_vin_request(self, session_id):
        """VIN 요청 처리 - ISO-TP 멀티프레임 지원"""
        self.logger.info(f"Session {session_id} requested VIN")

        # VIN을 ASCII 바이트로 변환
        vin_bytes = self.vehicle_vin.encode('ascii')

        # UDS 응답 (Service 0x49, PID 0x02) + VIN 데이터
        response_data = bytes([0x49, 0x02]) + vin_bytes
        total_length = len(response_data)

        self.logger.info(f"Sending VIN: {self.vehicle_vin} (Total: {total_length} bytes)")

        if total_length <= 6:
            # 단일 프레임 (Single Frame)
            sf_data = bytes([total_length]) + response_data
            sf_data += b'\x00' * (8 - len(sf_data))  # 패딩

            return {
                'can_id': 0x7E8,
                'data': sf_data
            }
        else:
            # 멀티프레임 (First Frame + Consecutive Frames)
            # ISO-TP 세션 초기화
            self.isotp_sessions[session_id] = {
                'data': response_data,
                'total_length': total_length,
                'sent_bytes': 0,
                'sequence_number': 1,
                'waiting_for_fc': True  # Flow Control 대기
            }

            # First Frame (FF) 전송
            ff_data = bytes([0x10 | ((total_length >> 8) & 0x0F), total_length & 0xFF])
            ff_data += response_data[:6]  # 첫 6바이트 포함

            self.isotp_sessions[session_id]['sent_bytes'] = 6

            self.logger.info(f"Sending First Frame: {total_length} bytes total, first 6 bytes included")

            return {
                'can_id': 0x7E8,
                'data': ff_data
            }

    def handle_flow_control(self, session_id, data):
        """Flow Control Frame 처리"""
        if session_id not in self.isotp_sessions:
            self.logger.info(f"No active ISO-TP session for {session_id}")
            return None

        if len(data) < 1:
            return None

        fc_flag = data[0] & 0x0F

        if fc_flag == 0x00:  # Continue To Send (CTS)
            self.logger.info(f"Received Flow Control CTS from {session_id}")
            return self.send_consecutive_frames(session_id)
        elif fc_flag == 0x01:  # Wait
            self.logger.info(f"Received Flow Control Wait from {session_id}")
            return None
        elif fc_flag == 0x02:  # Overflow/Abort
            self.logger.info(f"Received Flow Control Overflow from {session_id}")
            if session_id in self.isotp_sessions:
                del self.isotp_sessions[session_id]
            return None

        return None

    def send_consecutive_frames(self, session_id):
        """Consecutive Frame들을 전송"""
        if session_id not in self.isotp_sessions:
            return None

        session = self.isotp_sessions[session_id]
        data = session['data']
        sent_bytes = session['sent_bytes']
        sequence_number = session['sequence_number']

        if sent_bytes >= len(data):
            # 모든 데이터 전송 완료
            del self.isotp_sessions[session_id]
            self.logger.info(f"ISO-TP transmission completed for {session_id}")
            return None

        # Consecutive Frame 데이터 준비
        remaining_data = data[sent_bytes:]
        chunk_size = 7  # CF는 첫 바이트가 시퀀스 번호이므로 7바이트만 데이터
        chunk = remaining_data[:chunk_size]

        # Consecutive Frame 생성
        cf_data = bytes([0x20 | (sequence_number & 0x0F)]) + chunk
        cf_data += b'\x00' * (8 - len(cf_data))  # 패딩

        # 세션 정보 업데이트
        session['sent_bytes'] += len(chunk)
        session['sequence_number'] = (sequence_number + 1) % 16

        self.logger.info(f"Sending Consecutive Frame {sequence_number}: {len(chunk)} bytes")

        # 다음 CF가 있다면 계속 전송하도록 스케줄링
        if session['sent_bytes'] < len(data):
            # 실제 구현에서는 타이머를 사용하거나 즉시 다음 CF 전송
            pass
        else:
            # 전송 완료
            del self.isotp_sessions[session_id]
            self.logger.info(f"All Consecutive Frames sent for {session_id}")

        return {
            'can_id': 0x7E8,
            'data': cf_data
        }

    def send_to_session(self, session_id, can_msg):
        if session_id in self.sessions:
            msg_data = {
                'type': 'receive',
                'can_id': can_msg.can_id,
                'data': can_msg.data.hex(),
                'timestamp': can_msg.timestamp
            }
            self.send_raw_message(session_id, json.dumps(msg_data))
        else:
            self.message_queues[session_id].append(can_msg)

    def send_raw_message(self, session_id, message):
        try:
            session_info = self.sessions.get(session_id)
            if not session_info:
                return False

            socket_obj = session_info['socket']
            socket_obj.send((message + '\n').encode())
            return True

        except Exception as e:
            self.logger.error(f"Error sending to {session_id}: {e}")
            if session_id in self.sessions:
                del self.sessions[session_id]
            return False

    def send_queued_messages(self, session_id):
        if session_id in self.message_queues:
            for can_msg in self.message_queues[session_id]:
                self.send_to_session(session_id, can_msg)
            self.message_queues[session_id].clear()

    def stop(self):
        self.logger.info("Stopping Simple CAN Broker...")
        self.running = False

        for session_id, info in list(self.sessions.items()):
            try:
                info['socket'].close()
            except:
                pass

        if hasattr(self, 'server_socket'):
            self.server_socket.close()

        self.logger.info("Simple CAN Broker stopped")

if __name__ == "__main__":
    broker = SimpleCANBroker()
    try:
        broker.start()
    except KeyboardInterrupt:
        broker.logger.info("Received interrupt signal")
        broker.stop()
    except Exception as e:
        broker.logger.error(f"Fatal error: {e}")
        broker.stop()
