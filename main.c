#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum
{
    REG_AF,
    REG_BC,
    REG_DE,
    REG_HL,
    REG_SP,
    REG_PC,
    REGS,
};

struct cpu_state
{
    uint16_t regs[REGS];
    int ie;
} __attribute__((packed));

struct cpu
{
    uint8_t (*get_mem)(struct cpu * cpu, uint16_t addr);
    void (*set_mem)(struct cpu * cpu, uint16_t addr, uint8_t val);
    uint8_t (*port_ip)(struct cpu * cpu, uint16_t addr);
    void (*port_op)(struct cpu * cpu, uint16_t addr, uint8_t val);
    struct cpu_state cpu_state;
    uint64_t clk;
    uint8_t *mem;
};

uint8_t get_mem(struct cpu *cpu, uint16_t addr);
void set_mem(struct cpu *cpu, uint16_t addr, uint8_t val);
uint8_t port_ip(struct cpu *cpu, uint16_t addr);
void port_op(struct cpu *cpu, uint16_t addr, uint8_t val);

void reference_init(struct cpu_state *cpu_state);
void reference_read(struct cpu_state *cpu_state);
int reference_step(struct cpu_state *cpu_state);

enum
{
    INVALID_TYPE,
    ADC,
    ADD,
    CP,
    SBC,
    SUB,
    RLA,
    RLCA,
    RRA,
    RRCA,
    CCF,
    DAA,
    AND,
    OR,
    XOR,
    SCF,
    DEC,
    INC,
    CPL,
    CALL,
    DI,
    DJNZ,
    EI,
    PUTHLSP,
    EXAF,
    EXDEHL,
    EXX,
    HALT,
    IN,
    JP,
    JR,
    LD,
    NOP,
    OUT,
    POP,
    PUSH,
    RET,
    RST_00H,
    RST_08H,
    RST_10H,
    RST_18H,
    RST_20H,
    RST_28H,
    RST_30H,
    RST_38H,
};

enum
{
    INVALID_SUBJECT,
    IMM16,
    IMM8,
    PTR_BC,
    PTR_DE,
    PTR_HL,
    PTR_IMM16,
    PTR_IMM8,
    REG16_AF,
    REG16_BC,
    REG16_DE,
    REG16_HL,
    REG16_SP,
    REG8_A,
    REG8_B,
    REG8_C,
    REG8_D,
    REG8_E,
    REG8_H,
    REG8_L,
};

enum
{
    CARRY_U,
    CARRY_D,
    CARRY_R,
    CARRY_S,
    CARRY_X,
};

enum
{
    ZS_U,
    ZS_D,
};

enum
{
    COND_INVALID,
    COND_A,
    COND_C,
    COND_M,
    COND_NC,
    COND_NZ,
    COND_P,
    COND_PE,
    COND_PO,
    COND_Z,
};

struct opcode
{
    uint8_t size;
    uint8_t type;
    uint8_t dst;
    uint8_t alt;
    uint8_t cond;
    uint8_t carry;
    uint8_t zs;
    uint8_t slow;
    uint8_t fast;
}
opcodes[0x100] = {
    [0x8E]  =  {1,  ADC,      REG8_A,     PTR_HL,     0,        CARRY_D,  ZS_D,  7,   7,},
    [0x8F]  =  {1,  ADC,      REG8_A,     REG8_A,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x88]  =  {1,  ADC,      REG8_A,     REG8_B,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x89]  =  {1,  ADC,      REG8_A,     REG8_C,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x8A]  =  {1,  ADC,      REG8_A,     REG8_D,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x8B]  =  {1,  ADC,      REG8_A,     REG8_E,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x8C]  =  {1,  ADC,      REG8_A,     REG8_H,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x8D]  =  {1,  ADC,      REG8_A,     REG8_L,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xCE]  =  {2,  ADC,      REG8_A,     IMM8,       0,        CARRY_D,  ZS_D,  7,   7,},
    [0x86]  =  {1,  ADD,      REG8_A,     PTR_HL,     0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x87]  =  {1,  ADD,      REG8_A,     REG8_A,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x80]  =  {1,  ADD,      REG8_A,     REG8_B,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x81]  =  {1,  ADD,      REG8_A,     REG8_C,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x82]  =  {1,  ADD,      REG8_A,     REG8_D,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x83]  =  {1,  ADD,      REG8_A,     REG8_E,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x84]  =  {1,  ADD,      REG8_A,     REG8_H,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x85]  =  {1,  ADD,      REG8_A,     REG8_L,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xC6]  =  {2,  ADD,      REG8_A,     IMM8,       0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0xBE]  =  {1,  CP,       REG8_A,     PTR_HL,     0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0xBF]  =  {1,  CP,       REG8_A,     REG8_A,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xB8]  =  {1,  CP,       REG8_A,     REG8_B,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xB9]  =  {1,  CP,       REG8_A,     REG8_C,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xBA]  =  {1,  CP,       REG8_A,     REG8_D,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xBB]  =  {1,  CP,       REG8_A,     REG8_E,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xBC]  =  {1,  CP,       REG8_A,     REG8_H,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xBD]  =  {1,  CP,       REG8_A,     REG8_L,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xFE]  =  {2,  CP,       REG8_A,     IMM8,       0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x9E]  =  {1,  SBC,      REG8_A,     PTR_HL,     0,        CARRY_D,  ZS_D,  7,   7,},
    [0x9F]  =  {1,  SBC,      REG8_A,     REG8_A,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x98]  =  {1,  SBC,      REG8_A,     REG8_B,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x99]  =  {1,  SBC,      REG8_A,     REG8_C,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x9A]  =  {1,  SBC,      REG8_A,     REG8_D,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x9B]  =  {1,  SBC,      REG8_A,     REG8_E,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x9C]  =  {1,  SBC,      REG8_A,     REG8_H,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x9D]  =  {1,  SBC,      REG8_A,     REG8_L,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xDE]  =  {2,  SBC,      REG8_A,     IMM8,       0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x96]  =  {1,  SUB,      REG8_A,     PTR_HL,     0,        CARRY_D,  ZS_D,  7,   7,},
    [0x97]  =  {1,  SUB,      REG8_A,     REG8_A,     0,        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x90]  =  {1,  SUB,      REG8_A,     REG8_B,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x91]  =  {1,  SUB,      REG8_A,     REG8_C,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x92]  =  {1,  SUB,      REG8_A,     REG8_D,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x93]  =  {1,  SUB,      REG8_A,     REG8_E,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x94]  =  {1,  SUB,      REG8_A,     REG8_H,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0x95]  =  {1,  SUB,      REG8_A,     REG8_L,     0,        CARRY_D,  ZS_D,  4,   4,},
    [0xD6]  =  {2,  SUB,      REG8_A,     IMM8,       0,        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x09]  =  {1,  ADD,      REG16_HL,   REG16_BC,   0,        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x19]  =  {1,  ADD,      REG16_HL,   REG16_DE,   0,        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x29]  =  {1,  ADD,      REG16_HL,   REG16_HL,   0,        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x39]  =  {1,  ADD,      REG16_HL,   REG16_SP,   0,        CARRY_D,  ZS_U,  11,  11,},
    [0x17]  =  {1,  RLA,      REG8_A,     0,          0,        CARRY_D,  ZS_U,  4,   4,},
    [0x07]  =  {1,  RLCA,     REG8_A,     0,          0,        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x1F]  =  {1,  RRA,      REG8_A,     0,          0,        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x0F]  =  {1,  RRCA,     REG8_A,     0,          0,        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x3F]  =  {1,  CCF,      0,          0,          0,        CARRY_X,  ZS_U,  4,   4,},
    [0x27]  =  {1,  DAA,      0,          0,          0,        CARRY_X,  ZS_D,  4,   4,},   /*  required  */
    [0xA6]  =  {1,  AND,      REG8_A,     PTR_HL,     0,        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xA7]  =  {1,  AND,      REG8_A,     REG8_A,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA0]  =  {1,  AND,      REG8_A,     REG8_B,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA1]  =  {1,  AND,      REG8_A,     REG8_C,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xA2]  =  {1,  AND,      REG8_A,     REG8_D,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xA3]  =  {1,  AND,      REG8_A,     REG8_E,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xA4]  =  {1,  AND,      REG8_A,     REG8_H,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xA5]  =  {1,  AND,      REG8_A,     REG8_L,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xE6]  =  {2,  AND,      REG8_A,     IMM8,       0,        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xB6]  =  {1,  OR,       REG8_A,     PTR_HL,     0,        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xB7]  =  {1,  OR,       REG8_A,     REG8_A,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xB0]  =  {1,  OR,       REG8_A,     REG8_B,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xB1]  =  {1,  OR,       REG8_A,     REG8_C,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xB2]  =  {1,  OR,       REG8_A,     REG8_D,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xB3]  =  {1,  OR,       REG8_A,     REG8_E,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xB4]  =  {1,  OR,       REG8_A,     REG8_H,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xB5]  =  {1,  OR,       REG8_A,     REG8_L,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xF6]  =  {2,  OR,       REG8_A,     IMM8,       0,        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xAE]  =  {1,  XOR,      REG8_A,     PTR_HL,     0,        CARRY_R,  ZS_D,  7,   7,},
    [0xAF]  =  {1,  XOR,      REG8_A,     REG8_A,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA8]  =  {1,  XOR,      REG8_A,     REG8_B,     0,        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA9]  =  {1,  XOR,      REG8_A,     REG8_C,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xAA]  =  {1,  XOR,      REG8_A,     REG8_D,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xAB]  =  {1,  XOR,      REG8_A,     REG8_E,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xAC]  =  {1,  XOR,      REG8_A,     REG8_H,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xAD]  =  {1,  XOR,      REG8_A,     REG8_L,     0,        CARRY_R,  ZS_D,  4,   4,},
    [0xEE]  =  {2,  XOR,      REG8_A,     IMM8,       0,        CARRY_R,  ZS_D,  7,   7,},
    [0x37]  =  {1,  SCF,      0,          0,          0,        CARRY_S,  ZS_U,  4,   4,},   /*  required  */
    [0x35]  =  {1,  DEC,      PTR_HL,     0,          0,        CARRY_U,  ZS_D,  11,  11,},  /*  required  */
    [0x3D]  =  {1,  DEC,      REG8_A,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x05]  =  {1,  DEC,      REG8_B,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x0D]  =  {1,  DEC,      REG8_C,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x15]  =  {1,  DEC,      REG8_D,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x1D]  =  {1,  DEC,      REG8_E,     0,          0,        CARRY_U,  ZS_D,  4,   4,},
    [0x25]  =  {1,  DEC,      REG8_H,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x2D]  =  {1,  DEC,      REG8_L,     0,          0,        CARRY_U,  ZS_D,  4,   4,},
    [0x34]  =  {1,  INC,      PTR_HL,     0,          0,        CARRY_U,  ZS_D,  11,  11,},  /*  required  */
    [0x3C]  =  {1,  INC,      REG8_A,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x04]  =  {1,  INC,      REG8_B,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x0C]  =  {1,  INC,      REG8_C,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x14]  =  {1,  INC,      REG8_D,     0,          0,        CARRY_U,  ZS_D,  4,   4,},
    [0x1C]  =  {1,  INC,      REG8_E,     0,          0,        CARRY_U,  ZS_D,  4,   4,},
    [0x24]  =  {1,  INC,      REG8_H,     0,          0,        CARRY_U,  ZS_D,  4,   4,},
    [0x2C]  =  {1,  INC,      REG8_L,     0,          0,        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x2F]  =  {1,  CPL,      0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xDC]  =  {3,  CALL,     IMM16,      0,          COND_C,   CARRY_U,  ZS_U,  10,  17,},
    [0xFC]  =  {3,  CALL,     IMM16,      0,          COND_M,   CARRY_U,  ZS_U,  10,  17,},
    [0xD4]  =  {3,  CALL,     IMM16,      0,          COND_NC,  CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0xCD]  =  {3,  CALL,     IMM16,      0,          COND_A,   CARRY_U,  ZS_U,  17,  17,},  /*  required  */
    [0xC4]  =  {3,  CALL,     IMM16,      0,          COND_NZ,  CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0xF4]  =  {3,  CALL,     IMM16,      0,          COND_P,   CARRY_U,  ZS_U,  10,  17,},
    [0xEC]  =  {3,  CALL,     IMM16,      0,          COND_PE,  CARRY_U,  ZS_U,  10,  17,},
    [0xE4]  =  {3,  CALL,     IMM16,      0,          COND_PO,  CARRY_U,  ZS_U,  10,  17,},
    [0xCC]  =  {3,  CALL,     IMM16,      0,          COND_Z,   CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0x0B]  =  {1,  DEC,      REG16_BC,   0,          0,        CARRY_U,  ZS_U,  6,   6,},
    [0x1B]  =  {1,  DEC,      REG16_DE,   0,          0,        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x2B]  =  {1,  DEC,      REG16_HL,   0,          0,        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x3B]  =  {1,  DEC,      REG16_SP,   0,          0,        CARRY_U,  ZS_U,  6,   6,},
    [0xF3]  =  {1,  DI,       0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},
    [0x10]  =  {2,  DJNZ,     IMM8,       0,          0,        CARRY_U,  ZS_U,  13,  8,},
    [0xFB]  =  {1,  EI,       0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xE3]  =  {1,  PUTHLSP,  0,          0,          0,        CARRY_U,  ZS_U,  19,  19,},  /*  required  */
    [0x08]  =  {1,  EXAF,     0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},
    [0xEB]  =  {1,  EXDEHL,   0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xD9]  =  {1,  EXX,      0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},
    [0x76]  =  {1,  HALT,     0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},
    [0xDB]  =  {2,  IN,       IMM8,       0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0x03]  =  {1,  INC,      REG16_BC,   0,          0,        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x13]  =  {1,  INC,      REG16_DE,   0,          0,        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x23]  =  {1,  INC,      REG16_HL,   0,          0,        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x33]  =  {1,  INC,      REG16_SP,   0,          0,        CARRY_U,  ZS_U,  6,   6,},
    [0xE9]  =  {1,  JP,       REG16_HL,   0,          COND_A,   CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xDA]  =  {3,  JP,       IMM16,      0,          COND_C,   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xFA]  =  {3,  JP,       IMM16,      0,          COND_M,   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD2]  =  {3,  JP,       IMM16,      0,          COND_NC,  CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC3]  =  {3,  JP,       IMM16,      0,          COND_A,   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC2]  =  {3,  JP,       IMM16,      0,          COND_NZ,  CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xF2]  =  {3,  JP,       IMM16,      0,          COND_P,   CARRY_U,  ZS_U,  10,  10,},
    [0xEA]  =  {3,  JP,       IMM16,      0,          COND_PE,  CARRY_U,  ZS_U,  10,  10,},
    [0xE2]  =  {3,  JP,       IMM16,      0,          COND_PO,  CARRY_U,  ZS_U,  10,  10,},
    [0xCA]  =  {3,  JP,       IMM16,      0,          COND_Z,   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x38]  =  {2,  JR,       IMM8,       0,          COND_C,   CARRY_U,  ZS_U,  12,  7,},
    [0x18]  =  {2,  JR,       IMM8,       0,          COND_A,   CARRY_U,  ZS_U,  12,  12,},
    [0x30]  =  {2,  JR,       IMM8,       0,          COND_NC,  CARRY_U,  ZS_U,  12,  7,},
    [0x20]  =  {2,  JR,       IMM8,       0,          COND_NZ,  CARRY_U,  ZS_U,  12,  7,},
    [0x28]  =  {2,  JR,       IMM8,       0,          COND_Z,   CARRY_U,  ZS_U,  12,  7,},
    [0x02]  =  {1,  LD,       PTR_BC,     REG8_A,     0,        CARRY_U,  ZS_U,  7,   7,},
    [0x12]  =  {1,  LD,       PTR_DE,     REG8_A,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x77]  =  {1,  LD,       PTR_HL,     REG8_A,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x70]  =  {1,  LD,       PTR_HL,     REG8_B,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x71]  =  {1,  LD,       PTR_HL,     REG8_C,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x72]  =  {1,  LD,       PTR_HL,     REG8_D,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x73]  =  {1,  LD,       PTR_HL,     REG8_E,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x74]  =  {1,  LD,       PTR_HL,     REG8_H,     0,        CARRY_U,  ZS_U,  7,   7,},
    [0x75]  =  {1,  LD,       PTR_HL,     REG8_L,     0,        CARRY_U,  ZS_U,  7,   7,},
    [0x36]  =  {2,  LD,       PTR_HL,     IMM8,       0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x32]  =  {3,  LD,       PTR_IMM8,   REG8_A,     0,        CARRY_U,  ZS_U,  13,  13,},  /*  required  */
    [0x22]  =  {3,  LD,       PTR_IMM16,  REG16_HL,   0,        CARRY_U,  ZS_U,  16,  16,},  /*  required  */
    [0x0A]  =  {1,  LD,       REG8_A,     PTR_BC,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x1A]  =  {1,  LD,       REG8_A,     PTR_DE,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x7E]  =  {1,  LD,       REG8_A,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x3A]  =  {3,  LD,       REG8_A,     PTR_IMM8,   0,        CARRY_U,  ZS_U,  13,  13,},  /*  required  */
    [0x7F]  =  {1,  LD,       REG8_A,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x78]  =  {1,  LD,       REG8_A,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x79]  =  {1,  LD,       REG8_A,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7A]  =  {1,  LD,       REG8_A,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7B]  =  {1,  LD,       REG8_A,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7C]  =  {1,  LD,       REG8_A,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7D]  =  {1,  LD,       REG8_A,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x3E]  =  {2,  LD,       REG8_A,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x46]  =  {1,  LD,       REG8_B,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x47]  =  {1,  LD,       REG8_B,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x40]  =  {1,  LD,       REG8_B,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x41]  =  {1,  LD,       REG8_B,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x42]  =  {1,  LD,       REG8_B,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x43]  =  {1,  LD,       REG8_B,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x44]  =  {1,  LD,       REG8_B,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x45]  =  {1,  LD,       REG8_B,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x06]  =  {2,  LD,       REG8_B,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x01]  =  {3,  LD,       REG16_BC,   IMM16,      0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x4E]  =  {1,  LD,       REG8_C,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x4F]  =  {1,  LD,       REG8_C,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x48]  =  {1,  LD,       REG8_C,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x49]  =  {1,  LD,       REG8_C,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x4A]  =  {1,  LD,       REG8_C,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x4B]  =  {1,  LD,       REG8_C,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x4C]  =  {1,  LD,       REG8_C,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x4D]  =  {1,  LD,       REG8_C,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x0E]  =  {2,  LD,       REG8_C,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x56]  =  {1,  LD,       REG8_D,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x57]  =  {1,  LD,       REG8_D,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x50]  =  {1,  LD,       REG8_D,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x51]  =  {1,  LD,       REG8_D,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x52]  =  {1,  LD,       REG8_D,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x53]  =  {1,  LD,       REG8_D,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x54]  =  {1,  LD,       REG8_D,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x55]  =  {1,  LD,       REG8_D,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x16]  =  {2,  LD,       REG8_D,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x11]  =  {3,  LD,       REG16_DE,   IMM16,      0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x5E]  =  {1,  LD,       REG8_E,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x5F]  =  {1,  LD,       REG8_E,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x58]  =  {1,  LD,       REG8_E,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x59]  =  {1,  LD,       REG8_E,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x5A]  =  {1,  LD,       REG8_E,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x5B]  =  {1,  LD,       REG8_E,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x5C]  =  {1,  LD,       REG8_E,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x5D]  =  {1,  LD,       REG8_E,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x1E]  =  {2,  LD,       REG8_E,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},
    [0x66]  =  {1,  LD,       REG8_H,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x67]  =  {1,  LD,       REG8_H,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x60]  =  {1,  LD,       REG8_H,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x61]  =  {1,  LD,       REG8_H,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x62]  =  {1,  LD,       REG8_H,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x63]  =  {1,  LD,       REG8_H,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x64]  =  {1,  LD,       REG8_H,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x65]  =  {1,  LD,       REG8_H,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x26]  =  {2,  LD,       REG8_H,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x2A]  =  {3,  LD,       REG16_HL,   PTR_IMM16,  0,        CARRY_U,  ZS_U,  16,  16,},  /*  required  */
    [0x21]  =  {3,  LD,       REG16_HL,   IMM16,      0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x6E]  =  {1,  LD,       REG8_L,     PTR_HL,     0,        CARRY_U,  ZS_U,  7,   7,},
    [0x6F]  =  {1,  LD,       REG8_L,     REG8_A,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x68]  =  {1,  LD,       REG8_L,     REG8_B,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x69]  =  {1,  LD,       REG8_L,     REG8_C,     0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x6A]  =  {1,  LD,       REG8_L,     REG8_D,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x6B]  =  {1,  LD,       REG8_L,     REG8_E,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x6C]  =  {1,  LD,       REG8_L,     REG8_H,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x6D]  =  {1,  LD,       REG8_L,     REG8_L,     0,        CARRY_U,  ZS_U,  4,   4,},
    [0x2E]  =  {2,  LD,       REG8_L,     IMM8,       0,        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0xF9]  =  {1,  LD,       REG16_SP,   REG16_HL,   0,        CARRY_U,  ZS_U,  6,   6,},
    [0x31]  =  {3,  LD,       REG16_SP,   IMM16,      0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x00]  =  {1,  NOP,      0,          0,          0,        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xD3]  =  {2,  OUT,      IMM8,       0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xF1]  =  {1,  POP,      REG16_AF,   0,          0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC1]  =  {1,  POP,      REG16_BC,   0,          0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD1]  =  {1,  POP,      REG16_DE,   0,          0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xE1]  =  {1,  POP,      REG16_HL,   0,          0,        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xF5]  =  {1,  PUSH,     REG16_AF,   0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xC5]  =  {1,  PUSH,     REG16_BC,   0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xD5]  =  {1,  PUSH,     REG16_DE,   0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xE5]  =  {1,  PUSH,     REG16_HL,   0,          0,        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xC9]  =  {1,  RET,      0,          0,          COND_A,   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD8]  =  {1,  RET,      0,          0,          COND_C,   CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xF8]  =  {1,  RET,      0,          0,          COND_M,   CARRY_U,  ZS_U,  11,  5,},
    [0xD0]  =  {1,  RET,      0,          0,          COND_NC,  CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xC0]  =  {1,  RET,      0,          0,          COND_NZ,  CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xF0]  =  {1,  RET,      0,          0,          COND_P,   CARRY_U,  ZS_U,  11,  5,},
    [0xE8]  =  {1,  RET,      0,          0,          COND_PE,  CARRY_U,  ZS_U,  11,  5,},
    [0xE0]  =  {1,  RET,      0,          0,          COND_PO,  CARRY_U,  ZS_U,  11,  5,},
    [0xC8]  =  {1,  RET,      0,          0,          COND_Z,   CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xC7]  =  {1,  RST_00H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xCF]  =  {1,  RST_08H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xD7]  =  {1,  RST_10H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xDF]  =  {1,  RST_18H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xE7]  =  {1,  RST_20H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xEF]  =  {1,  RST_28H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xF7]  =  {1,  RST_30H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
    [0xFF]  =  {1,  RST_38H,  0,          0,          0,        CARRY_U,  ZS_U,  11,  11,},
};

enum
{
    FLAG_C = 0,
    FLAG_N = 1,
    FLAG_PV = 2,
    FLAG_H = 4,
    FLAG_Z = 6,
    FLAG_S = 7,

    FLAG_BIT_C = 1 << FLAG_C,
    FLAG_BIT_N = 1 << FLAG_N,
    FLAG_BIT_PV = 1 << FLAG_PV,
    FLAG_BIT_H = 1 << FLAG_H,
    FLAG_BIT_Z = 1 << FLAG_Z,
    FLAG_BIT_S = 1 << FLAG_S,
};

int reg_verbose;
#define REG_ACCESS(HL, H, L, REG) \
uint16_t get_ ## HL(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG]; \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
uint16_t get_ ## H(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG] >> 8 & 0xff; \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
uint16_t get_ ## L(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG] >> 0 & 0xff; \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
void set_ ## HL(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    cpu->cpu_state.regs[REG] = val; \
} \
\
void set_ ## H(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    cpu->cpu_state.regs[REG] &= 0xff << 0; \
    cpu->cpu_state.regs[REG] |= (0xff & val) << 8; \
} \
\
void set_ ## L(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    cpu->cpu_state.regs[REG] &= 0xff << 8; \
    cpu->cpu_state.regs[REG] |= (0xff & val) << 0; \
}

uint16_t get_ie(struct cpu *cpu, uint16_t addr)
{
    return cpu->cpu_state.ie;
}

void set_ie(struct cpu *cpu, uint16_t addr, uint8_t val)
{
    cpu->cpu_state.ie = !!val;
}

REG_ACCESS(af, a, f, REG_AF) 
REG_ACCESS(bc, b, c, REG_BC) 
REG_ACCESS(de, d, e, REG_DE) 
REG_ACCESS(hl, h, l, REG_HL) 
REG_ACCESS(pc, pc_h, pc_l, REG_PC) 
REG_ACCESS(sp, sp_h, sp_l, REG_SP)

 struct access
 {
     uint16_t (*get)(struct cpu * cpu, uint16_t addr);
     void (*set)(struct cpu * cpu, uint16_t addr, uint16_t val);
     int reg16;
 };

 uint16_t get_imm16(struct cpu *cpu, uint16_t addr)
{
    uint16_t pc = get_pc(cpu, 0);
    uint16_t lo = cpu->get_mem(cpu, pc + 0);
    uint16_t hi = cpu->get_mem(cpu, pc + 1);

    return hi << 8 | lo << 0;
}

uint16_t get_imm8(struct cpu *cpu, uint16_t addr)
{
    uint16_t pc = get_pc(cpu, 0);
    uint16_t lo = cpu->get_mem(cpu, pc + 0);

    return lo;
}

uint16_t get_ptr_bc(struct cpu *cpu, uint16_t addr)
{
    return cpu->get_mem(cpu, get_bc(cpu, 0));
}

void set_ptr_bc(struct cpu *cpu, uint16_t addr, uint16_t val)
{
    cpu->set_mem(cpu, get_bc(cpu, 0), val);
}

uint16_t get_ptr_de(struct cpu *cpu, uint16_t addr)
{
    return cpu->get_mem(cpu, get_de(cpu, 0));
}

void set_ptr_de(struct cpu *cpu, uint16_t addr, uint16_t val)
{
    cpu->set_mem(cpu, get_de(cpu, 0), val);
}

uint16_t get_ptr_hl(struct cpu *cpu, uint16_t addr)
{
    return cpu->get_mem(cpu, get_hl(cpu, 0));
}

void set_ptr_hl(struct cpu *cpu, uint16_t addr, uint16_t val)
{
    cpu->set_mem(cpu, get_hl(cpu, 0), val);
}

uint16_t get_ptr_imm8(struct cpu *cpu, uint16_t addr)
{
    return cpu->get_mem(cpu, get_imm16(cpu, 0));
}

void set_ptr_imm8(struct cpu *cpu, uint16_t addr, uint16_t val)
{
    cpu->set_mem(cpu, get_imm16(cpu, 0), val);
}

uint16_t get_ptr_imm16(struct cpu *cpu, uint16_t addr)
{
    addr = get_imm16(cpu, 0);

    uint16_t hi = cpu->get_mem(cpu, addr + 1);
    uint16_t lo = cpu->get_mem(cpu, addr + 0);

    return hi << 8 | lo << 0;
}

void set_ptr_imm16(struct cpu *cpu, uint16_t addr, uint16_t val)
{
    addr = get_imm16(cpu, 0);

    cpu->set_mem(cpu, addr + 1, val >> 8 & 0xff);
    cpu->set_mem(cpu, addr + 0, val >> 0 & 0xff);
}

struct access accesses[] = {
    [INVALID_SUBJECT] = {},
    [IMM16] = {
            .get = get_imm16,
        },
    [IMM8] = {
            .get = get_imm8,
        },
    [PTR_BC] = {
            .get = get_ptr_bc,
            .set = set_ptr_bc,
        },
    [PTR_DE] = {
            .get = get_ptr_de,
            .set = set_ptr_de,
        },
    [PTR_HL] = {
            .get = get_ptr_hl,
            .set = set_ptr_hl,
        },
    [PTR_IMM16] = {
            .get = get_ptr_imm16,
            .set = set_ptr_imm16,
        },
    [PTR_IMM8] = {
            .get = get_ptr_imm8,
            .set = set_ptr_imm8,
        },
    [REG16_AF] = {
            .get = get_af,
            .set = set_af,
            .reg16 = 1,
        },
    [REG16_BC] = {
            .get = get_bc,
            .set = set_bc,
            .reg16 = 1,
        },
    [REG16_DE] = {
            .get = get_de,
            .set = set_de,
            .reg16 = 1,
        },
    [REG16_HL] = {
            .get = get_hl,
            .set = set_hl,
            .reg16 = 1,
        },
    [REG16_SP] = {
            .get = get_sp,
            .set = set_sp,
            .reg16 = 1,
        },
    [REG8_A] = {
            .get = get_a,
            .set = set_a,
        },
    [REG8_B] = {
            .get = get_b,
            .set = set_b,
        },
    [REG8_C] = {
            .get = get_c,
            .set = set_c,
        },
    [REG8_D] = {
            .get = get_d,
            .set = set_d,
        },
    [REG8_E] = {
            .get = get_e,
            .set = set_e,
        },
    [REG8_H] = {
            .get = get_h,
            .set = set_h,
        },
    [REG8_L] = {
            .get = get_l,
            .set = set_l,
        },
};

int cond(struct cpu *cpu, int test)
{
    uint8_t f = get_f(cpu, 0);

    switch (test)
    {
        case COND_A: /* Always. */
            return 1;
        case COND_C:
            return !!(f & FLAG_BIT_C);
        case COND_M:
            return !!(f & FLAG_BIT_S);
        case COND_NC:
            return !(f & FLAG_BIT_C); /* Watch out, this has only one inversion ... */
        case COND_NZ:
            return !(f & FLAG_BIT_Z); /* Watch out, this has only one inversion ... */
        case COND_P:
            return !(f & FLAG_BIT_S); /* Watch out, this has only one inversion ... */
        case COND_PE:
            assert(0);
            break;
        case COND_PO:
            assert(0);
            break;
        case COND_Z:
            return !!(f & FLAG_BIT_Z);
        default:
            assert(0);
    }
    assert(0);
    return 0;
}

void set_flags(struct cpu *cpu, struct opcode *opcode, uint32_t res_val, int reg16)
{
    uint8_t flags = 0;

    if (reg16)
    {
        flags |= !!(res_val & 0x10000) << FLAG_C;
        flags |= !!(res_val & 0x08000) << FLAG_S;
        flags |= !(res_val & 0x00ffff) << FLAG_Z;
    }
    else
    {
        flags |= !!(res_val & 0x100) << FLAG_C;
        flags |= !!(res_val & 0x080) << FLAG_S;
        flags |= !(res_val & 0x00ff) << FLAG_Z;
    }

    uint8_t flag_mask = (opcode->carry ? FLAG_BIT_C : 0) | (opcode->zs ? FLAG_BIT_Z | FLAG_BIT_S : 0) | FLAG_BIT_H;

    set_f(cpu, 0, (get_f(cpu, 0) & ~flag_mask) | (flags & flag_mask));
}

uint32_t step(struct cpu *cpu)
{
    uint16_t pc = get_pc(cpu, 0);
    uint8_t op = cpu->get_mem(cpu, pc);
    struct opcode *opcode = opcodes + op;

    set_pc(cpu, 0, pc + 1);

    switch (opcode->type)
    {
        case NOP:
            break;

        case LD:
            {
                struct access dst = accesses[opcode->dst];
                struct access alt = accesses[opcode->alt];

                dst.set(cpu, pc, alt.get(cpu, pc));
                break;
            }

        case ADD:
        case ADC:
        case SUB:
        case SBC:
        case CP:
        case AND:
        case OR:
        case XOR:
            {
                struct access dst = accesses[opcode->dst];
                uint32_t dst_val = dst.get(cpu, pc);

                struct access alt = accesses[opcode->alt];
                uint32_t alt_val = alt.get(cpu, pc);

                uint32_t res_val = dst_val;

                switch (opcode->type)
                {
                    case ADD:
                        res_val += alt_val;
                        break;
                    case ADC:
                        res_val += alt_val + cond(cpu, COND_C);
                        break;
                    case SUB:
                        res_val -= alt_val;
                        break;
                    case SBC:
                        res_val -= alt_val + cond(cpu, COND_C);
                        break;
                    case CP:
                        res_val -= alt_val;
                        break;
                    case AND:
                        res_val &= alt_val;
                        break;
                    case OR:
                        res_val |= alt_val;
                        break;
                    case XOR:
                        res_val ^= alt_val;
                        break;
                }

                if (!dst.reg16) /* For my application the half carry only needs to work for these instructions. */
                {
                    switch (opcode->type)
                    {
                        case ADD:
                        case ADC:
                            {
                                uint8_t half_carry_bit = FLAG_BIT_H & (dst_val ^ alt_val ^ res_val);

                                set_f(cpu, 0, get_f(cpu, 0) | half_carry_bit);
                                break;
                            }
                    }
                }

                if (dst.reg16)
                {
                    assert(alt.reg16);
                }

                set_flags(cpu, opcode, res_val, dst.reg16);

                if (opcode->type != CP)
                {
                    dst.set(cpu, 0, res_val);
                }

                break;
            }

        case DAA:
            {
                uint8_t a = get_a(cpu, 0);
                uint8_t al = a & 0xf;
                uint8_t f = get_f(cpu, 0);

                if (f & FLAG_BIT_H || al > 9)
                {
                    a += 0x06;
                }

                if (cond(cpu, COND_C) || a > 0x99)
                {
                    a += 0x60;
                    f |= FLAG_BIT_C;
                }

                f |= al >= 0xA ? FLAG_BIT_H : 0;
                f |= a & 0x80 ? FLAG_BIT_S : 0;
                f |= a ? 0 : FLAG_BIT_Z;

                set_a(cpu, 0, a);
                set_f(cpu, 0, f);
                break;
            }

        case RLA:
            {
                struct access dst = accesses[opcode->dst];
                uint32_t res_val = dst.get(cpu, pc);
                int carry = cond(cpu, COND_C);

                uint8_t f = get_f(cpu, 0) & ~FLAG_BIT_C;
                set_f(cpu, 0, f | ((res_val & 0x80) ? FLAG_BIT_C : 0));

                res_val <<= 1;
                res_val |= !!carry << 0;

                dst.set(cpu, pc, res_val);
                break;
            }

        case RLCA:
            {
                struct access dst = accesses[opcode->dst];
                uint32_t res_val = dst.get(cpu, pc);
                int bit = !!(res_val & 0x80);

                uint8_t f = get_f(cpu, 0) & ~FLAG_BIT_C;
                set_f(cpu, 0, f | (bit ? FLAG_BIT_C : 0));

                res_val <<= 1;
                res_val |= bit << 0;

                dst.set(cpu, pc, res_val);
                break;
            }

        case RRA:
            {
                struct access dst = accesses[opcode->dst];
                uint32_t res_val = dst.get(cpu, pc);
                int carry = cond(cpu, COND_C);

                uint8_t f = get_f(cpu, 0) & ~FLAG_BIT_C;
                set_f(cpu, 0, f | ((res_val & 0x01) ? FLAG_BIT_C : 0));

                res_val >>= 1;
                res_val |= !!carry << 7;

                dst.set(cpu, pc, res_val);
                break;
            }

        case RRCA:
            {
                struct access dst = accesses[opcode->dst];
                uint32_t res_val = dst.get(cpu, pc);
                int bit = !!(res_val & 0x01);

                uint8_t f = get_f(cpu, 0) & ~FLAG_BIT_C;
                set_f(cpu, 0, f | (bit ? FLAG_BIT_C : 0));

                res_val >>= 1;
                res_val |= bit << 7;

                dst.set(cpu, pc, res_val);
                break;
            }

        case DEC:
            {
                struct access dst = accesses[opcode->dst];

                if (dst.reg16)
                {
                    dst.set(cpu, pc, dst.get(cpu, pc) - 1);
                }
                else
                {
                    struct access dst = accesses[opcode->dst];
                    uint32_t res_val = dst.get(cpu, pc);

                    --res_val;
                    set_flags(cpu, opcode, res_val, dst.reg16);

                    dst.set(cpu, pc, res_val);
                }
                break;
            }

        case INC:
            {
                struct access dst = accesses[opcode->dst];

                if (dst.reg16)
                {
                    dst.set(cpu, pc, dst.get(cpu, pc) + 1);
                }
                else
                {
                    struct access dst = accesses[opcode->dst];
                    uint32_t res_val = dst.get(cpu, pc);

                    ++res_val;
                    set_flags(cpu, opcode, res_val, dst.reg16);
                    dst.set(cpu, pc, res_val);
                }
                break;
            }

        case CALL:
            {
                struct access dst = accesses[opcode->dst];
                assert(opcode->dst == IMM16);

                if (cond(cpu, opcode->cond))
                {
                    uint16_t addr = dst.get(cpu, 0);
                    uint16_t sp = get_sp(cpu, 0);
                    uint16_t link = pc + opcode->size;

                    cpu->set_mem(cpu, sp - 1, link >> 8);
                    cpu->set_mem(cpu, sp - 2, link >> 0);
                    set_sp(cpu, 0, sp - 2);

                    set_pc(cpu, 0, addr);
                    cpu->clk += opcode->slow;
                    return opcode->slow;
                }
                break;
            }

        case JP:
            {
                if (cond(cpu, opcode->cond))
                {
                    struct access dst = accesses[opcode->dst];
                    uint16_t addr = dst.get(cpu, 0);

                    set_pc(cpu, 0, addr);
                    cpu->clk += opcode->slow;
                    return opcode->slow;
                }
                break;
            }

        case JR:
            assert(0);
            if (cond(cpu, opcode->cond))
            {
                assert(opcode->dst == IMM8);
                struct access dst = accesses[opcode->dst];
                int8_t off = (int8_t)dst.get(cpu, 0);
                int32_t addr = (int32_t)pc + opcode->size + off;

                set_pc(cpu, 0, (uint16_t)addr);
                cpu->clk += opcode->slow;
                return opcode->slow;
            }
            break;

        case RET:
            {
                if (cond(cpu, opcode->cond))
                {
                    uint16_t sp = get_sp(cpu, 0);
                    uint16_t lo = cpu->get_mem(cpu, sp + 0);
                    uint16_t hi = cpu->get_mem(cpu, sp + 1);
                    set_sp(cpu, 0, sp + 2);

                    set_pc(cpu, 0, hi << 8 | lo << 0);
                    cpu->clk += opcode->slow;
                    return opcode->slow;
                }

                break;
            }

        case POP:
            {
                uint16_t sp = get_sp(cpu, 0);
                uint16_t lo = cpu->get_mem(cpu, sp + 0);
                uint16_t hi = cpu->get_mem(cpu, sp + 1);
                set_sp(cpu, 0, sp + 2);

                struct access dst = accesses[opcode->dst];
                assert(dst.reg16);
                dst.set(cpu, 0, hi << 8 | lo << 0);
                break;
            }

        case PUSH:
            {
                struct access dst = accesses[opcode->dst];
                assert(dst.reg16);
                uint16_t val = dst.get(cpu, 0);
                uint16_t sp = get_sp(cpu, 0);
                cpu->set_mem(cpu, sp - 1, val >> 8);
                cpu->set_mem(cpu, sp - 2, val >> 0);
                set_sp(cpu, 0, sp - 2);
                break;
            }

        case SCF:
            set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_C);
            break;

        case EI:
            set_ie(cpu, 0, 1);
            break;

        case CPL:
            set_a(cpu, 0, ~get_a(cpu, 0));
            if (0)
            {
                set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_H);
                set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_N);
            }
            break;

        case EXDEHL:
            {
                uint16_t tmp = get_de(cpu, 0);
                set_de(cpu, 0, get_hl(cpu, 0));
                set_hl(cpu, 0, tmp);
                break;
            }

        case PUTHLSP:
            {
                uint16_t sp = get_sp(cpu, 0);

                uint8_t l = get_l(cpu, 0);
                set_l(cpu, 0, cpu->get_mem(cpu, sp + 0));
                cpu->set_mem(cpu, sp + 0, l);

                uint8_t h = get_h(cpu, 0);
                set_h(cpu, 0, cpu->get_mem(cpu, sp + 1));
                cpu->set_mem(cpu, sp + 1, h);

                break;
            }

        case IN:
            {
                struct access dst = accesses[opcode->dst];
                uint8_t port = dst.get(cpu, 0);
                set_a(cpu, 0, cpu->port_ip(cpu, port));
                break;
            }

        case OUT:
            {
                struct access dst = accesses[opcode->dst];
                uint8_t port = dst.get(cpu, 0);

                cpu->port_op(cpu, port, get_a(cpu, 0));
                break;
            }

            /* unused */
        case INVALID_TYPE:
        case CCF:
        case DI:
        case DJNZ:
        case EXAF:
        case EXX:
        case HALT:
        case RST_00H:
        case RST_08H:
        case RST_10H:
        case RST_18H:
        case RST_20H:
        case RST_28H:
        case RST_30H:
        case RST_38H:
            assert(0);
    }

    set_pc(cpu, 0, pc + opcode->size);

    cpu->clk += opcode->fast;
    return opcode->fast;
}

void intr(struct cpu *cpu, uint16_t addr)
{
    uint16_t pc = get_pc(cpu, 0);

    if (cpu->cpu_state.ie)
    {
        uint16_t sp = get_sp(cpu, 0);
        uint16_t link = pc;

        cpu->set_mem(cpu, sp - 1, link >> 8);
        cpu->set_mem(cpu, sp - 2, link >> 0);
        set_sp(cpu, 0, sp - 2);

        set_pc(cpu, 0, addr);
    }
}

void dump_cpu_state(struct cpu_state *cpu_state)
{
    int save_reg_verbose = reg_verbose;
    reg_verbose = 0;
    printf("a:%02x ", cpu_state->regs[REG_AF] >> 8 & 0xff);
    printf("f:%02x ", cpu_state->regs[REG_AF] >> 0 & 0xff);
    printf("bc:%04x ", cpu_state->regs[REG_BC]);
    printf("de:%04x ", cpu_state->regs[REG_DE]);
    printf("hl:%04x ", cpu_state->regs[REG_HL]);
    printf("pc:%04x ", cpu_state->regs[REG_PC]);
    printf("sp:%04x ", cpu_state->regs[REG_SP]);
    printf("ie:%d\n", cpu_state->ie);
    reg_verbose = save_reg_verbose;
}

enum
{
    GET_MEM,
    SET_MEM,
    PORT_IP,
    PORT_OP,
};

struct cpu cpu;

void run(int cycles)
{
    while (cycles > 0)
    {
        cycles -= step(&cpu);
    }
}

void dump(void)
{
    printf("cpu.cpu_state.regs[REG_AF]:%04x\n", cpu.cpu_state.regs[REG_AF]);
    printf("cpu.cpu_state.regs[REG_BC]:%04x\n", cpu.cpu_state.regs[REG_BC]);
    printf("cpu.cpu_state.regs[REG_DE]:%04x\n", cpu.cpu_state.regs[REG_DE]);
    printf("cpu.cpu_state.regs[REG_HL]:%04x\n", cpu.cpu_state.regs[REG_HL]);
    printf("cpu.cpu_state.regs[REG_SP]:%04x\n", cpu.cpu_state.regs[REG_SP]);
    printf("cpu.cpu_state.regs[REG_PC]:%04x\n", cpu.cpu_state.regs[REG_PC]);
    printf("cpu.cpu_state.ie:%04x\n",           cpu.cpu_state.ie);
}

uint8_t mem[0x10000];

uint8_t get_mem(struct cpu *cpu, uint16_t addr)
{
    return mem[addr];
}

void set_mem(struct cpu *cpu, uint16_t addr, uint8_t val)
{
    mem[addr] = val;
}

static uint8_t dip0 = 0x0f;
static uint8_t dip1 = 0x08;
static uint8_t dip2 = 0x01;

static uint16_t shift_reg;
static int shift_off;

uint8_t port_ip(struct cpu *cpu, uint16_t addr)
{
    switch (addr)
    {
        case 0:
            return dip0;
        case 1:
            return dip1;
        case 2:
            return dip2;
        case 3:
            return shift_reg >> (8 - shift_off);
        default:
            printf("Port read %d\n", addr);
    }

    return 0x00;
}

void port_op(struct cpu *cpu, uint16_t addr, uint8_t val)
{
    switch (addr)
    {
        case 2:
            shift_off = val & 7;
            break;
        case 3:
            break;
        case 4:
            shift_reg = (shift_reg >> 8) | ((uint16_t)val << 8);
            break;
        case 5:
            break;
        case 6:
            break;
        default:
            printf("Port write %d %d\n", addr, val);
    }
}

void init(struct cpu *cpu)
{
    memset(cpu, 0, sizeof *cpu);

    cpu->get_mem = get_mem;
    cpu->set_mem = set_mem;
    cpu->port_ip = port_ip;
    cpu->port_op = port_op;

    cpu->cpu_state.regs[REG_AF] = 0x0002;
    cpu->cpu_state.regs[REG_SP] = 0xF000;
    cpu->cpu_state.regs[REG_PC] = 0x0001;
}

void shadow_step(void)
{
    step(&cpu);
}

void shadow_intr(uint16_t addr)
{
    intr(&cpu, addr);
}

#include <stdio.h>
#include <SDL2/SDL.h>

struct machine 
{
    SDL_Renderer *renderer;
    SDL_Texture *texture;
};

struct machine *machine;

void render()
{
    uint16_t vram_base = 0x2400;
    uint32_t screen_buf[256 * 224];
    uint32_t *screen_ptr = screen_buf;

    while (vram_base < 0x4000)
    {
        uint8_t b = mem[vram_base];

        *screen_ptr++ = ((b >> 0) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 1) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 2) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 3) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 4) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 5) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 6) & 1) ? 0xFFFFFFFF : 0xFF000000;
        *screen_ptr++ = ((b >> 7) & 1) ? 0xFFFFFFFF : 0xFF000000;

        vram_base += 1;
    }

    SDL_UpdateTexture(machine->texture, NULL, screen_buf, 256 * 4);

    SDL_RenderClear(machine->renderer);

    SDL_Rect dest_rect = { 0, 0, 256, 224 };
    SDL_RenderCopyEx(machine->renderer, machine->texture, NULL, &dest_rect, 270, NULL, 0);
    SDL_RenderPresent(machine->renderer);
}

void get_input()
{
    static SDL_Event event = { };

    dip0 = 0x0E;
    dip1 &= 0xE0;

    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
            case SDL_KEYUP:
                switch (event.key.keysym.sym)
                {
                    case SDLK_LEFT:
                        dip1 &= ~(1 << 5);
                        break;
                    case SDLK_RIGHT:
                        dip1 &= ~(1 << 6);
                        break;
                    default:
                        break;
                }
                break;
            case SDL_KEYDOWN:
                switch (event.key.keysym.sym)
                {
                    case SDLK_LEFT:
                        dip1 |= (1 << 5);
                        break;
                    case SDLK_RIGHT:
                        dip1 |= (1 << 6);
                        break;
                    case SDLK_c:
                        dip1 |= (1 << 0);
                        break;
                    case SDLK_x:
                        dip1 |= (1 << 2);
                        break;
                    case SDLK_z:
                        dip1 |= (1 << 4);
                        break;
                    default:
                        break;
                }
                break;
            case SDL_QUIT:
                exit(0);
                break;
            default:
                break;
        }
    }
}

struct machine *init_machine(void)
{
    struct machine *machine = calloc(sizeof machine, 1);
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) != 0)
    {
        printf("Cannot initialize SDL\n");
        exit(EXIT_FAILURE);
    }

    atexit(SDL_Quit);

    static SDL_Window *win;
    if (SDL_CreateWindowAndRenderer(256, 256, SDL_WINDOW_OPENGL, &win, &machine->renderer))
    {
        printf("Cannot create a new window\n");
        exit(EXIT_FAILURE);
    }

    machine->texture = SDL_CreateTexture(machine->renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 256, 224);
    return machine;
}

int main(int argc, char *argv[])
{
    machine = init_machine();

    init(&cpu);

    char *bank_name[] = { "invaders.h", "invaders.g", "invaders.f", "invaders.e" };

    for (int i = 0; i < 4; i++)
    {
        FILE *fp = fopen(bank_name[i], "rb");
        if (!fp)
        {
            return 0;
        }
        if (fread(mem + (i * 0x0800), 1, 0x0800, fp) != 0x0800)
        {
            return 0;
        }
        fclose(fp);
    }

    mem[0] = 0xc3;

    for(;;)
    {
        run(17066);
        shadow_intr(8);
        render();
        run(17066);
        shadow_intr(16);
        get_input();
        SDL_Delay(15);

    }

    return 1;
}

