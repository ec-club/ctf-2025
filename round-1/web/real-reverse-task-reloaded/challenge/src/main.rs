use actix_web::{App, HttpRequest, HttpResponse, HttpServer, Responder, get, middleware::Logger};
use hex_literal::hex;
use log::{debug, error, info};
use sha3::{
    Shake128,
    digest::{ExtendableOutput, Update, XofReader},
};

mod magic;

#[get("/flag")]
async fn get_flag(req: HttpRequest) -> impl Responder {
    let conn_info = req.peer_addr();
    let client_ip = conn_info.map(|addr| addr.ip().to_string());
    if client_ip.is_none() {
        error!("Could not determine client IP.");
        return HttpResponse::InternalServerError().body("Please create a thread in Discord.");
    }

    let mut hasher = Shake128::default();
    hasher.update(client_ip.as_ref().unwrap().as_bytes());
    let mut reader = hasher.finalize_xof();
    let mut hash_bytes = [0u8; 4];
    reader.read(&mut hash_bytes);
    let expected_hash = hex!("1337c0de");
    let mut result = 0;
    for (a, b) in hash_bytes.iter().zip(expected_hash.iter()) {
        result |= a ^ b;
    }
    if result != 0 {
        debug!(
            "Client IP {} failed hash check. Hash: {}",
            client_ip.unwrap(),
            hex::encode(hash_bytes)
        );
        return HttpResponse::Forbidden().body("Access denied.");
    }

    let flag = magic::generate_flag();
    info!("Releasing flag {} for IP: {}", flag, client_ip.unwrap());
    return HttpResponse::Ok().body(flag);
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    let host = std::env::var("HOST").unwrap_or_else(|_| "::".to_string());
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    HttpServer::new(|| App::new().wrap(Logger::default()).service(get_flag))
        .bind((host, port.parse::<u16>().unwrap()))?
        .run()
        .await
}
