#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

#define SLOTS 8
#define SLOT_SIZE 0x60

static char *slots[SLOTS];

static char *clipboard;

static int valid_index(int idx) {
    return (idx >= 0 && idx <= SLOTS);
}

void new(int idx);
void delete(int idx);
void print(int idx);
void update(int idx);
void copy(int idx);
void paste(int idx);

void init()
{
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);
}

void menu(void) {
    puts("============== MENU ==============");
    puts("1) new <index>     - allocate a slot (index 0..7)");
    puts("2) delete <index>  - free a slot");
    puts("3) print <index>    - print contents of a slot");
    puts("4) update <index>   - write data into a slot");
    puts("5) copy <index>    - copy slot contents into clipboard");
    puts("6) paste <index>   - paste clipboard into slot");
    puts("7) help            - show this menu");
    puts("8) exit            - quit");
    puts("==================================");
}

void new(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    slots[idx] = malloc(SLOT_SIZE);
    if (!slots[idx]) {
        perror("malloc");
        exit(1);
    }
    printf("[+] allocated slot %d \n", idx);
}

void delete(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    if (slots[idx] == NULL) {
        puts("[-] slot is already empty");
        return;
    }
    free(slots[idx]);
    slots[idx] = NULL;
    printf("[+] freed slot %d\n", idx);
}

void print(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    if (slots[idx] == NULL) {
        puts("[-] slot is empty");
        return;
    }
    printf("\n[slot %d] contents: ", idx);
    write(1, slots[idx], SLOT_SIZE);
}

void update(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    if (slots[idx] == NULL) {
        puts("[-] slot is not allocated");
        return;
    }
    printf("enter data for slot %d: ", idx);
    
    read(0, slots[idx], SLOT_SIZE);

    slots[idx][strcspn(slots[idx], "\n")] = '\0';
    printf("[+] wrote %zu bytes into slot %d\n", strlen(slots[idx]), idx);
}

void copy(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    if (slots[idx] == NULL) {
        puts("[-] slot is empty");
        return;
    }
    clipboard = slots[idx];
    printf("[+] copy slot %d to clipboard\n", idx);
}

void paste(int idx) {
    if (!valid_index(idx)) {
        puts("[-] invalid index (must be 0..7)");
        return;
    }
    if (slots[idx] != NULL) {
        puts("[-] slot is allocated");
        return;
    }
    if (clipboard == NULL) {
        puts("[-] clipboard is empty");
        return;
    }
    slots[idx] = malloc(SLOT_SIZE);
    if (!slots[idx]) {
        perror("malloc");
        exit(1);
    }
    memcpy(slots[idx], clipboard, SLOT_SIZE);
    clipboard = NULL; 
    printf("[+] pasted into slot %d\n", idx);
}

int main(void) {
    char line[512];

    init();

    for (int i = 0; i < SLOTS; ++i) {
        slots[i] = NULL;
    }

    menu();
    while (1) {
        printf("\n> ");
        if (!fgets(line, sizeof(line), stdin)) {
            puts("\n[!] EOF received, exiting.");
            break;
        }

        char *p = line;
        while (isspace((unsigned char)*p)) ++p;
        if (*p == '\0') continue;

        char cmd[32];
        int idx = -1;
        if (sscanf(p, "%31s %d", cmd, &idx) < 1) continue;

        if (strcmp(cmd, "help") == 0 || strcmp(cmd, "menu") == 0) {
            menu();
        } else if (strcmp(cmd, "exit") == 0 || strcmp(cmd, "quit") == 0) {
            puts("[*] bye");
            break;
        } else if (strcmp(cmd, "new") == 0) {
            new(idx);
        } else if (strcmp(cmd, "delete") == 0) {
            delete(idx);
        } else if (strcmp(cmd, "print") == 0) {
            print(idx);
        } else if (strcmp(cmd, "update") == 0) {
            update(idx);
        } else if (strcmp(cmd, "copy") == 0) {
            copy(idx);
        } else if (strcmp(cmd, "paste") == 0) {
            paste(idx);
        } else {
            puts("[-] unknown command. Type 'help' for menu.");
        }
    }

    return 0;
}
