#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <seccomp.h>
#include <sys/mman.h>
#include <sys/prctl.h>

void alarm_handler()
{
  puts("TIME OUT");
  exit(-1);
}

void init()
{
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);
  signal(SIGALRM, alarm_handler);
  alarm(10);
}

void caja_uno()
{
  prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
  scmp_filter_ctx ctx;
  ctx = seccomp_init(SCMP_ACT_ALLOW);
  if (ctx == NULL)
  {
    exit(0);
  }
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(execve), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(execveat), 0);
  seccomp_load(ctx);
}

void caja_dos()
{
  scmp_filter_ctx ctx;
  ctx = seccomp_init(SCMP_ACT_ALLOW);
  if (ctx == NULL)
  {
    exit(0);
  }
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(write), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(writev), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(pwritev), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(send), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(sendto), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(sendmsg), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(sendfile), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(sendfile64), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(sendmmsg), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(vmsplice), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(splice), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(fork), 0);
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(exit), 0); // 💀
  seccomp_rule_add(ctx, SCMP_ACT_KILL, SCMP_SYS(exit_group), 0); // 💀
  seccomp_load(ctx);
}

const int SHELLCODE_SIZE = 0x1000;
void main(int argc, char *argv[])
{
  char flag[256];
  strcpy(flag, argv[1]);
  int FLAG_SIZE = strlen(flag) + 1;

  char *shellcode = mmap(NULL, SHELLCODE_SIZE + FLAG_SIZE, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  void (*sc)();

  init();
  caja_uno();

  read(0, shellcode, SHELLCODE_SIZE);
  memcpy(shellcode + SHELLCODE_SIZE, flag, FLAG_SIZE);
  memset(flag, 0, sizeof(flag));

  caja_dos();
  mprotect(shellcode, SHELLCODE_SIZE + FLAG_SIZE, PROT_READ | PROT_EXEC);
  sc = (void *)shellcode;
  sc();
}
