#include <assert.h>
#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "symbols.h"

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

#define TRACE(T) TRACE_ ## T
enum
{
    TRACE(REG8_A),
    TRACE(REG8_F),
    TRACE(REG8_B),
    TRACE(REG8_C),
    TRACE(REG8_D),
    TRACE(REG8_E),
    TRACE(REG8_H),
    TRACE(REG8_L),

    TRACE(FLAG_BIT_C),
    TRACE(FLAG_BIT_N),
    TRACE(FLAG_BIT_PV),
    TRACE(FLAG_BIT_H),
    TRACE(FLAG_BIT_Z),
    TRACE(FLAG_BIT_S),
    TRACES,
};

char *trace_reg_str(int trace_reg)
{
    switch (trace_reg)
    {
        case TRACE(REG8_A):
            return "A";
        case TRACE(REG8_F):
            return "F";
        case TRACE(REG8_B):
            return "B";
        case TRACE(REG8_C):
            return "C";
        case TRACE(REG8_D):
            return "D";
        case TRACE(REG8_E):
            return "E";
        case TRACE(REG8_H):
            return "H";
        case TRACE(REG8_L):
            return "L";
        default:
            return "?";
    }
}

struct setat
{
    uint16_t inat;
    uint16_t func;
    uint32_t call;
    uint16_t sub_depth;
};

struct sub_elem
{
    uint16_t inat;
    uint16_t intr;
    uint64_t clk;
};

struct cpu
{
    uint8_t (*get_mem)(struct cpu * cpu, uint16_t addr);
    void (*set_mem)(struct cpu * cpu, uint16_t addr, uint8_t val);
    uint8_t (*port_ip)(struct cpu * cpu, uint16_t addr);
    void (*port_op)(struct cpu * cpu, uint16_t addr, uint8_t val);
    struct cpu_state cpu_state;
    uint64_t clk[2];
    uint8_t *mem;

    uint16_t intr;
    uint16_t inat;
    uint16_t next;
    uint16_t jump;
    uint32_t call;
    int sub_depth_intr;
    int sub_depth;
    struct sub_elem sub_stack[0x100];
    struct setat setat[2][TRACES];
    char coverage[2][0x10000];
};

uint8_t get_mem(struct cpu *cpu, uint16_t addr);
void set_mem(struct cpu *cpu, uint16_t addr, uint8_t val);
uint8_t port_ip(struct cpu *cpu, uint16_t addr);
void port_op(struct cpu *cpu, uint16_t addr, uint8_t val);

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

#define STRINGIZE_IMPL(x) #x
#define STRINGIZE(x) STRINGIZE_IMPL(x)

#define INIT(A, B, C, D) A, B, C, D, STRINGIZE(A D B C)

const struct opcode
{
    uint8_t size;
    uint8_t type;
    uint8_t dst;
    uint8_t alt;
    uint8_t cond;
    char *dasm;
    uint8_t carry;
    uint8_t zs;
    uint8_t slow;
    uint8_t fast;
}
opcodes[0x100] = {
    [0x8E]  =  {1, INIT(ADC,      REG8_A,     PTR_HL,      0),        CARRY_D,  ZS_D,  7,   7,},
    [0x8F]  =  {1, INIT(ADC,      REG8_A,     REG8_A,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x88]  =  {1, INIT(ADC,      REG8_A,     REG8_B,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x89]  =  {1, INIT(ADC,      REG8_A,     REG8_C,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x8A]  =  {1, INIT(ADC,      REG8_A,     REG8_D,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x8B]  =  {1, INIT(ADC,      REG8_A,     REG8_E,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x8C]  =  {1, INIT(ADC,      REG8_A,     REG8_H,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x8D]  =  {1, INIT(ADC,      REG8_A,     REG8_L,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xCE]  =  {2, INIT(ADC,      REG8_A,     IMM8,        0),        CARRY_D,  ZS_D,  7,   7,},
    [0x86]  =  {1, INIT(ADD,      REG8_A,     PTR_HL,      0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x87]  =  {1, INIT(ADD,      REG8_A,     REG8_A,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x80]  =  {1, INIT(ADD,      REG8_A,     REG8_B,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x81]  =  {1, INIT(ADD,      REG8_A,     REG8_C,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x82]  =  {1, INIT(ADD,      REG8_A,     REG8_D,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x83]  =  {1, INIT(ADD,      REG8_A,     REG8_E,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x84]  =  {1, INIT(ADD,      REG8_A,     REG8_H,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x85]  =  {1, INIT(ADD,      REG8_A,     REG8_L,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xC6]  =  {2, INIT(ADD,      REG8_A,     IMM8,        0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0xBE]  =  {1, INIT(CP,       REG8_A,     PTR_HL,      0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0xBF]  =  {1, INIT(CP,       REG8_A,     REG8_A,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xB8]  =  {1, INIT(CP,       REG8_A,     REG8_B,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xB9]  =  {1, INIT(CP,       REG8_A,     REG8_C,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xBA]  =  {1, INIT(CP,       REG8_A,     REG8_D,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xBB]  =  {1, INIT(CP,       REG8_A,     REG8_E,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xBC]  =  {1, INIT(CP,       REG8_A,     REG8_H,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0xBD]  =  {1, INIT(CP,       REG8_A,     REG8_L,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xFE]  =  {2, INIT(CP,       REG8_A,     IMM8,        0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x9E]  =  {1, INIT(SBC,      REG8_A,     PTR_HL,      0),        CARRY_D,  ZS_D,  7,   7,},
    [0x9F]  =  {1, INIT(SBC,      REG8_A,     REG8_A,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x98]  =  {1, INIT(SBC,      REG8_A,     REG8_B,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x99]  =  {1, INIT(SBC,      REG8_A,     REG8_C,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x9A]  =  {1, INIT(SBC,      REG8_A,     REG8_D,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x9B]  =  {1, INIT(SBC,      REG8_A,     REG8_E,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x9C]  =  {1, INIT(SBC,      REG8_A,     REG8_H,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x9D]  =  {1, INIT(SBC,      REG8_A,     REG8_L,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xDE]  =  {2, INIT(SBC,      REG8_A,     IMM8,        0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x96]  =  {1, INIT(SUB,      REG8_A,     PTR_HL,      0),        CARRY_D,  ZS_D,  7,   7,},
    [0x97]  =  {1, INIT(SUB,      REG8_A,     REG8_A,      0),        CARRY_D,  ZS_D,  4,   4,},   /*  required  */
    [0x90]  =  {1, INIT(SUB,      REG8_A,     REG8_B,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x91]  =  {1, INIT(SUB,      REG8_A,     REG8_C,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x92]  =  {1, INIT(SUB,      REG8_A,     REG8_D,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x93]  =  {1, INIT(SUB,      REG8_A,     REG8_E,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x94]  =  {1, INIT(SUB,      REG8_A,     REG8_H,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0x95]  =  {1, INIT(SUB,      REG8_A,     REG8_L,      0),        CARRY_D,  ZS_D,  4,   4,},
    [0xD6]  =  {2, INIT(SUB,      REG8_A,     IMM8,        0),        CARRY_D,  ZS_D,  7,   7,},   /*  required  */
    [0x09]  =  {1, INIT(ADD,      REG16_HL,   REG16_BC,    0),        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x19]  =  {1, INIT(ADD,      REG16_HL,   REG16_DE,    0),        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x29]  =  {1, INIT(ADD,      REG16_HL,   REG16_HL,    0),        CARRY_D,  ZS_U,  11,  11,},  /*  required  */
    [0x39]  =  {1, INIT(ADD,      REG16_HL,   REG16_SP,    0),        CARRY_D,  ZS_U,  11,  11,},
    [0x17]  =  {1, INIT(RLA,      REG8_A,     0,           0),        CARRY_D,  ZS_U,  4,   4,},
    [0x07]  =  {1, INIT(RLCA,     REG8_A,     0,           0),        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x1F]  =  {1, INIT(RRA,      REG8_A,     0,           0),        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x0F]  =  {1, INIT(RRCA,     REG8_A,     0,           0),        CARRY_D,  ZS_U,  4,   4,},   /*  required  */
    [0x3F]  =  {1, INIT(CCF,      0,          0,           0),        CARRY_X,  ZS_U,  4,   4,},
    [0x27]  =  {1, INIT(DAA,      0,          0,           0),        CARRY_X,  ZS_D,  4,   4,},   /*  required  */
    [0xA6]  =  {1, INIT(AND,      REG8_A,     PTR_HL,      0),        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xA7]  =  {1, INIT(AND,      REG8_A,     REG8_A,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA0]  =  {1, INIT(AND,      REG8_A,     REG8_B,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA1]  =  {1, INIT(AND,      REG8_A,     REG8_C,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xA2]  =  {1, INIT(AND,      REG8_A,     REG8_D,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xA3]  =  {1, INIT(AND,      REG8_A,     REG8_E,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xA4]  =  {1, INIT(AND,      REG8_A,     REG8_H,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xA5]  =  {1, INIT(AND,      REG8_A,     REG8_L,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xE6]  =  {2, INIT(AND,      REG8_A,     IMM8,        0),        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xB6]  =  {1, INIT(OR,       REG8_A,     PTR_HL,      0),        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xB7]  =  {1, INIT(OR,       REG8_A,     REG8_A,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xB0]  =  {1, INIT(OR,       REG8_A,     REG8_B,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xB1]  =  {1, INIT(OR,       REG8_A,     REG8_C,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xB2]  =  {1, INIT(OR,       REG8_A,     REG8_D,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xB3]  =  {1, INIT(OR,       REG8_A,     REG8_E,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xB4]  =  {1, INIT(OR,       REG8_A,     REG8_H,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xB5]  =  {1, INIT(OR,       REG8_A,     REG8_L,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xF6]  =  {2, INIT(OR,       REG8_A,     IMM8,        0),        CARRY_R,  ZS_D,  7,   7,},   /*  required  */
    [0xAE]  =  {1, INIT(XOR,      REG8_A,     PTR_HL,      0),        CARRY_R,  ZS_D,  7,   7,},
    [0xAF]  =  {1, INIT(XOR,      REG8_A,     REG8_A,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA8]  =  {1, INIT(XOR,      REG8_A,     REG8_B,      0),        CARRY_R,  ZS_D,  4,   4,},   /*  required  */
    [0xA9]  =  {1, INIT(XOR,      REG8_A,     REG8_C,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xAA]  =  {1, INIT(XOR,      REG8_A,     REG8_D,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xAB]  =  {1, INIT(XOR,      REG8_A,     REG8_E,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xAC]  =  {1, INIT(XOR,      REG8_A,     REG8_H,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xAD]  =  {1, INIT(XOR,      REG8_A,     REG8_L,      0),        CARRY_R,  ZS_D,  4,   4,},
    [0xEE]  =  {2, INIT(XOR,      REG8_A,     IMM8,        0),        CARRY_R,  ZS_D,  7,   7,},
    [0x37]  =  {1, INIT(SCF,      0,          0,           0),        CARRY_S,  ZS_U,  4,   4,},   /*  required  */
    [0x35]  =  {1, INIT(DEC,      PTR_HL,     0,           0),        CARRY_U,  ZS_D,  11,  11,},  /*  required  */
    [0x3D]  =  {1, INIT(DEC,      REG8_A,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x05]  =  {1, INIT(DEC,      REG8_B,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x0D]  =  {1, INIT(DEC,      REG8_C,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x15]  =  {1, INIT(DEC,      REG8_D,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x1D]  =  {1, INIT(DEC,      REG8_E,     0,           0),        CARRY_U,  ZS_D,  4,   4,},
    [0x25]  =  {1, INIT(DEC,      REG8_H,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x2D]  =  {1, INIT(DEC,      REG8_L,     0,           0),        CARRY_U,  ZS_D,  4,   4,},
    [0x34]  =  {1, INIT(INC,      PTR_HL,     0,           0),        CARRY_U,  ZS_D,  11,  11,},  /*  required  */
    [0x3C]  =  {1, INIT(INC,      REG8_A,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x04]  =  {1, INIT(INC,      REG8_B,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x0C]  =  {1, INIT(INC,      REG8_C,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x14]  =  {1, INIT(INC,      REG8_D,     0,           0),        CARRY_U,  ZS_D,  4,   4,},
    [0x1C]  =  {1, INIT(INC,      REG8_E,     0,           0),        CARRY_U,  ZS_D,  4,   4,},
    [0x24]  =  {1, INIT(INC,      REG8_H,     0,           0),        CARRY_U,  ZS_D,  4,   4,},
    [0x2C]  =  {1, INIT(INC,      REG8_L,     0,           0),        CARRY_U,  ZS_D,  4,   4,},   /*  required  */
    [0x2F]  =  {1, INIT(CPL,      0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xDC]  =  {3, INIT(CALL,     IMM16,      0,           COND_C),   CARRY_U,  ZS_U,  10,  17,},
    [0xFC]  =  {3, INIT(CALL,     IMM16,      0,           COND_M),   CARRY_U,  ZS_U,  10,  17,},
    [0xD4]  =  {3, INIT(CALL,     IMM16,      0,           COND_NC),  CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0xCD]  =  {3, INIT(CALL,     IMM16,      0,           COND_A),   CARRY_U,  ZS_U,  17,  17,},  /*  required  */
    [0xC4]  =  {3, INIT(CALL,     IMM16,      0,           COND_NZ),  CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0xF4]  =  {3, INIT(CALL,     IMM16,      0,           COND_P),   CARRY_U,  ZS_U,  10,  17,},
    [0xEC]  =  {3, INIT(CALL,     IMM16,      0,           COND_PE),  CARRY_U,  ZS_U,  10,  17,},
    [0xE4]  =  {3, INIT(CALL,     IMM16,      0,           COND_PO),  CARRY_U,  ZS_U,  10,  17,},
    [0xCC]  =  {3, INIT(CALL,     IMM16,      0,           COND_Z),   CARRY_U,  ZS_U,  10,  17,},  /*  required  */
    [0x0B]  =  {1, INIT(DEC,      REG16_BC,   0,           0),        CARRY_U,  ZS_U,  6,   6,},
    [0x1B]  =  {1, INIT(DEC,      REG16_DE,   0,           0),        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x2B]  =  {1, INIT(DEC,      REG16_HL,   0,           0),        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x3B]  =  {1, INIT(DEC,      REG16_SP,   0,           0),        CARRY_U,  ZS_U,  6,   6,},
    [0xF3]  =  {1, INIT(DI,       0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},
    [0x10]  =  {2, INIT(DJNZ,     IMM8,       0,           0),        CARRY_U,  ZS_U,  13,  8,},
    [0xFB]  =  {1, INIT(EI,       0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xE3]  =  {1, INIT(PUTHLSP,  0,          0,           0),        CARRY_U,  ZS_U,  19,  19,},  /*  required  */
    [0x08]  =  {1, INIT(EXAF,     0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},
    [0xEB]  =  {1, INIT(EXDEHL,   0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xD9]  =  {1, INIT(EXX,      0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},
    [0x76]  =  {1, INIT(HALT,     0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},
    [0xDB]  =  {2, INIT(IN,       IMM8,       0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0x03]  =  {1, INIT(INC,      REG16_BC,   0,           0),        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x13]  =  {1, INIT(INC,      REG16_DE,   0,           0),        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x23]  =  {1, INIT(INC,      REG16_HL,   0,           0),        CARRY_U,  ZS_U,  6,   6,},   /*  required  */
    [0x33]  =  {1, INIT(INC,      REG16_SP,   0,           0),        CARRY_U,  ZS_U,  6,   6,},
    [0xE9]  =  {1, INIT(JP,       REG16_HL,   0,           COND_A),   CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xDA]  =  {3, INIT(JP,       IMM16,      0,           COND_C),   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xFA]  =  {3, INIT(JP,       IMM16,      0,           COND_M),   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD2]  =  {3, INIT(JP,       IMM16,      0,           COND_NC),  CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC3]  =  {3, INIT(JP,       IMM16,      0,           COND_A),   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC2]  =  {3, INIT(JP,       IMM16,      0,           COND_NZ),  CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xF2]  =  {3, INIT(JP,       IMM16,      0,           COND_P),   CARRY_U,  ZS_U,  10,  10,},
    [0xEA]  =  {3, INIT(JP,       IMM16,      0,           COND_PE),  CARRY_U,  ZS_U,  10,  10,},
    [0xE2]  =  {3, INIT(JP,       IMM16,      0,           COND_PO),  CARRY_U,  ZS_U,  10,  10,},
    [0xCA]  =  {3, INIT(JP,       IMM16,      0,           COND_Z),   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x38]  =  {2, INIT(JR,       IMM8,       0,           COND_C),   CARRY_U,  ZS_U,  12,  7,},
    [0x18]  =  {2, INIT(JR,       IMM8,       0,           COND_A),   CARRY_U,  ZS_U,  12,  12,},
    [0x30]  =  {2, INIT(JR,       IMM8,       0,           COND_NC),  CARRY_U,  ZS_U,  12,  7,},
    [0x20]  =  {2, INIT(JR,       IMM8,       0,           COND_NZ),  CARRY_U,  ZS_U,  12,  7,},
    [0x28]  =  {2, INIT(JR,       IMM8,       0,           COND_Z),   CARRY_U,  ZS_U,  12,  7,},
    [0x02]  =  {1, INIT(LD,       PTR_BC,     REG8_A,      0),        CARRY_U,  ZS_U,  7,   7,},
    [0x12]  =  {1, INIT(LD,       PTR_DE,     REG8_A,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x77]  =  {1, INIT(LD,       PTR_HL,     REG8_A,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x70]  =  {1, INIT(LD,       PTR_HL,     REG8_B,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x71]  =  {1, INIT(LD,       PTR_HL,     REG8_C,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x72]  =  {1, INIT(LD,       PTR_HL,     REG8_D,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x73]  =  {1, INIT(LD,       PTR_HL,     REG8_E,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x74]  =  {1, INIT(LD,       PTR_HL,     REG8_H,      0),        CARRY_U,  ZS_U,  7,   7,},
    [0x75]  =  {1, INIT(LD,       PTR_HL,     REG8_L,      0),        CARRY_U,  ZS_U,  7,   7,},
    [0x36]  =  {2, INIT(LD,       PTR_HL,     IMM8,        0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x32]  =  {3, INIT(LD,       PTR_IMM8,   REG8_A,      0),        CARRY_U,  ZS_U,  13,  13,},  /*  required  */
    [0x22]  =  {3, INIT(LD,       PTR_IMM16,  REG16_HL,    0),        CARRY_U,  ZS_U,  16,  16,},  /*  required  */
    [0x0A]  =  {1, INIT(LD,       REG8_A,     PTR_BC,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x1A]  =  {1, INIT(LD,       REG8_A,     PTR_DE,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x7E]  =  {1, INIT(LD,       REG8_A,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x3A]  =  {3, INIT(LD,       REG8_A,     PTR_IMM8,    0),        CARRY_U,  ZS_U,  13,  13,},  /*  required  */
    [0x7F]  =  {1, INIT(LD,       REG8_A,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x78]  =  {1, INIT(LD,       REG8_A,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x79]  =  {1, INIT(LD,       REG8_A,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7A]  =  {1, INIT(LD,       REG8_A,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7B]  =  {1, INIT(LD,       REG8_A,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7C]  =  {1, INIT(LD,       REG8_A,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x7D]  =  {1, INIT(LD,       REG8_A,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x3E]  =  {2, INIT(LD,       REG8_A,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x46]  =  {1, INIT(LD,       REG8_B,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x47]  =  {1, INIT(LD,       REG8_B,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x40]  =  {1, INIT(LD,       REG8_B,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x41]  =  {1, INIT(LD,       REG8_B,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x42]  =  {1, INIT(LD,       REG8_B,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x43]  =  {1, INIT(LD,       REG8_B,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x44]  =  {1, INIT(LD,       REG8_B,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x45]  =  {1, INIT(LD,       REG8_B,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x06]  =  {2, INIT(LD,       REG8_B,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x01]  =  {3, INIT(LD,       REG16_BC,   IMM16,       0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x4E]  =  {1, INIT(LD,       REG8_C,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x4F]  =  {1, INIT(LD,       REG8_C,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x48]  =  {1, INIT(LD,       REG8_C,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x49]  =  {1, INIT(LD,       REG8_C,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x4A]  =  {1, INIT(LD,       REG8_C,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x4B]  =  {1, INIT(LD,       REG8_C,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x4C]  =  {1, INIT(LD,       REG8_C,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x4D]  =  {1, INIT(LD,       REG8_C,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x0E]  =  {2, INIT(LD,       REG8_C,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x56]  =  {1, INIT(LD,       REG8_D,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x57]  =  {1, INIT(LD,       REG8_D,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x50]  =  {1, INIT(LD,       REG8_D,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x51]  =  {1, INIT(LD,       REG8_D,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x52]  =  {1, INIT(LD,       REG8_D,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x53]  =  {1, INIT(LD,       REG8_D,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x54]  =  {1, INIT(LD,       REG8_D,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x55]  =  {1, INIT(LD,       REG8_D,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x16]  =  {2, INIT(LD,       REG8_D,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x11]  =  {3, INIT(LD,       REG16_DE,   IMM16,       0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x5E]  =  {1, INIT(LD,       REG8_E,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x5F]  =  {1, INIT(LD,       REG8_E,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x58]  =  {1, INIT(LD,       REG8_E,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x59]  =  {1, INIT(LD,       REG8_E,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x5A]  =  {1, INIT(LD,       REG8_E,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x5B]  =  {1, INIT(LD,       REG8_E,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x5C]  =  {1, INIT(LD,       REG8_E,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x5D]  =  {1, INIT(LD,       REG8_E,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x1E]  =  {2, INIT(LD,       REG8_E,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},
    [0x66]  =  {1, INIT(LD,       REG8_H,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x67]  =  {1, INIT(LD,       REG8_H,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x60]  =  {1, INIT(LD,       REG8_H,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x61]  =  {1, INIT(LD,       REG8_H,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x62]  =  {1, INIT(LD,       REG8_H,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x63]  =  {1, INIT(LD,       REG8_H,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x64]  =  {1, INIT(LD,       REG8_H,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x65]  =  {1, INIT(LD,       REG8_H,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x26]  =  {2, INIT(LD,       REG8_H,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0x2A]  =  {3, INIT(LD,       REG16_HL,   PTR_IMM16,   0),        CARRY_U,  ZS_U,  16,  16,},  /*  required  */
    [0x21]  =  {3, INIT(LD,       REG16_HL,   IMM16,       0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x6E]  =  {1, INIT(LD,       REG8_L,     PTR_HL,      0),        CARRY_U,  ZS_U,  7,   7,},
    [0x6F]  =  {1, INIT(LD,       REG8_L,     REG8_A,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x68]  =  {1, INIT(LD,       REG8_L,     REG8_B,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x69]  =  {1, INIT(LD,       REG8_L,     REG8_C,      0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0x6A]  =  {1, INIT(LD,       REG8_L,     REG8_D,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x6B]  =  {1, INIT(LD,       REG8_L,     REG8_E,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x6C]  =  {1, INIT(LD,       REG8_L,     REG8_H,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x6D]  =  {1, INIT(LD,       REG8_L,     REG8_L,      0),        CARRY_U,  ZS_U,  4,   4,},
    [0x2E]  =  {2, INIT(LD,       REG8_L,     IMM8,        0),        CARRY_U,  ZS_U,  7,   7,},   /*  required  */
    [0xF9]  =  {1, INIT(LD,       REG16_SP,   REG16_HL,    0),        CARRY_U,  ZS_U,  6,   6,},
    [0x31]  =  {3, INIT(LD,       REG16_SP,   IMM16,       0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0x00]  =  {1, INIT(NOP,      0,          0,           0),        CARRY_U,  ZS_U,  4,   4,},   /*  required  */
    [0xD3]  =  {2, INIT(OUT,      IMM8,       0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xF1]  =  {1, INIT(POP,      REG16_AF,   0,           0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xC1]  =  {1, INIT(POP,      REG16_BC,   0,           0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD1]  =  {1, INIT(POP,      REG16_DE,   0,           0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xE1]  =  {1, INIT(POP,      REG16_HL,   0,           0),        CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xF5]  =  {1, INIT(PUSH,     REG16_AF,   0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xC5]  =  {1, INIT(PUSH,     REG16_BC,   0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xD5]  =  {1, INIT(PUSH,     REG16_DE,   0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xE5]  =  {1, INIT(PUSH,     REG16_HL,   0,           0),        CARRY_U,  ZS_U,  11,  11,},  /*  required  */
    [0xC9]  =  {1, INIT(RET,      0,          0,           COND_A),   CARRY_U,  ZS_U,  10,  10,},  /*  required  */
    [0xD8]  =  {1, INIT(RET,      0,          0,           COND_C),   CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xF8]  =  {1, INIT(RET,      0,          0,           COND_M),   CARRY_U,  ZS_U,  11,  5,},
    [0xD0]  =  {1, INIT(RET,      0,          0,           COND_NC),  CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xC0]  =  {1, INIT(RET,      0,          0,           COND_NZ),  CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xF0]  =  {1, INIT(RET,      0,          0,           COND_P),   CARRY_U,  ZS_U,  11,  5,},
    [0xE8]  =  {1, INIT(RET,      0,          0,           COND_PE),  CARRY_U,  ZS_U,  11,  5,},
    [0xE0]  =  {1, INIT(RET,      0,          0,           COND_PO),  CARRY_U,  ZS_U,  11,  5,},
    [0xC8]  =  {1, INIT(RET,      0,          0,           COND_Z),   CARRY_U,  ZS_U,  11,  5,},   /*  required  */
    [0xC7]  =  {1, INIT(RST_00H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xCF]  =  {1, INIT(RST_08H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xD7]  =  {1, INIT(RST_10H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xDF]  =  {1, INIT(RST_18H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xE7]  =  {1, INIT(RST_20H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xEF]  =  {1, INIT(RST_28H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xF7]  =  {1, INIT(RST_30H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
    [0xFF]  =  {1, INIT(RST_38H,  0,          0,           0),        CARRY_U,  ZS_U,  11,  11,},
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

void get_trace(struct cpu *cpu, int trace_reg)
{
    struct setat *setat = cpu->setat[cpu->intr] + trace_reg;

    if (setat->call == cpu->call)
    {
        return; /* The register was set earlier in this call. */
    }

    if (setat->sub_depth != cpu->sub_depth)
    {
        uint16_t func = cpu->sub_stack[cpu->sub_depth - 1].inat;
        int setat_sub_depth = setat->sub_depth;
        int cpu_sub_depth = cpu->sub_depth;

        if (cpu->intr)
        {
            setat_sub_depth -= cpu->sub_depth_intr;
            cpu_sub_depth -= cpu->sub_depth_intr;
        }

        printf("    intr:%d func:%04x %s %c ", cpu->intr, func, trace_reg_str(trace_reg), setat_sub_depth > cpu_sub_depth ? 'R' : 'C');
        printf("func:%04x getat:%04x sub_depth:%u ", func, cpu->inat, cpu_sub_depth);
        printf("func:%04x setat:%04x sub_depth:%u ", setat->func, setat->inat, setat_sub_depth);
        printf("\n");
    }
}

void set_trace(struct cpu *cpu, int trace_reg)
{
    cpu->setat[cpu->intr][trace_reg] = (struct setat) {
        .inat = cpu->inat,
        .func = cpu->sub_stack[cpu->sub_depth - 1].inat,
        .call = cpu->call,
        .sub_depth = cpu->sub_depth,
    };
}

#define TRACE_MAP(L, U) \
void get_trace_ ## L(struct cpu *cpu) \
{ \
    get_trace(cpu, TRACE_REG8_ ## U); \
} \
void set_trace_ ## L(struct cpu *cpu) \
{ \
    set_trace(cpu, TRACE_REG8_ ## U); \
}

TRACE_MAP(a, A)
TRACE_MAP(f, F)
TRACE_MAP(b, B)
TRACE_MAP(c, C)
TRACE_MAP(d, D)
TRACE_MAP(e, E)
TRACE_MAP(h, H)
TRACE_MAP(l, L)

#define TRACE_NUL(L) \
void get_trace_ ## L(struct cpu *cpu) \
{ \
} \
void set_trace_ ## L(struct cpu *cpu) \
{ \
}

TRACE_NUL(pc_h)
TRACE_NUL(pc_l)
TRACE_NUL(sp_h)
TRACE_NUL(sp_l)

int reg_verbose;
#define REG_ACCESS(HL, H, L, REG) \
uint16_t get_ ## HL(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG]; \
    get_trace_ ## H(cpu); \
    get_trace_ ## L(cpu); \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
uint16_t get_ ## H(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG] >> 8 & 0xff; \
    get_trace_ ## H(cpu); \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
uint16_t get_ ## L(struct cpu *cpu, uint16_t addr) \
{ \
    uint16_t ret = cpu->cpu_state.regs[REG] >> 0 & 0xff; \
    get_trace_ ## L(cpu); \
    if (reg_verbose) printf("%s %04x\n", __func__, ret); \
    return ret; \
} \
\
void set_ ## HL(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    set_trace_ ## H(cpu); \
    set_trace_ ## L(cpu); \
    cpu->cpu_state.regs[REG] = val; \
} \
\
void set_ ## H(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    set_trace_ ## H(cpu); \
    cpu->cpu_state.regs[REG] &= 0xff << 0; \
    cpu->cpu_state.regs[REG] |= (0xff & val) << 8; \
} \
\
void set_ ## L(struct cpu *cpu, uint16_t addr, uint16_t val) \
{ \
    if (reg_verbose) printf("%s %04x\n", __func__, val); \
    set_trace_ ## L(cpu); \
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

void call(struct cpu *cpu)
{
    ++cpu->call;

    if (cpu->sub_depth >= 1)
    {
        printf("call intr:%d %04x %04x\n", cpu->intr, cpu->sub_stack[cpu->sub_depth - 1].inat, get_pc(cpu, 0));
    }

    cpu->sub_stack[cpu->sub_depth++] = (struct sub_elem) {
        .inat = get_pc(cpu, 0),
        .intr = cpu->intr,
        .clk = cpu->clk[cpu->intr],
    };
}

void ret(struct cpu *cpu)
{
    --cpu->sub_depth;
    struct sub_elem *sub_elem = cpu->sub_stack + cpu->sub_depth;
    printf("ret intr:%d %04x %04x %" PRId64 "\n", cpu->intr, sub_elem->inat, get_pc(cpu, 0), cpu->clk[sub_elem->intr] - sub_elem->clk);
}

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

const struct access accesses[] = {
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
    if (test == COND_A)
    {
        return 1;
    }

    uint8_t f = get_f(cpu, 0);

    switch (test)
    {
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

void set_flags(struct cpu *cpu, const struct opcode *opcode, uint32_t res_val, int reg16)
{
    uint8_t flags = 0;

    if (reg16)
    {
        flags |= !!(res_val & 0x10000) * FLAG_BIT_C;
        flags |= !!(res_val & 0x08000) * FLAG_BIT_S;
        flags |= !(res_val & 0x00ffff) * FLAG_BIT_Z;
    }
    else
    {
        flags |= !!(res_val & 0x100) * FLAG_BIT_C;
        flags |= !!(res_val & 0x080) * FLAG_BIT_S;
        flags |= !(res_val & 0x00ff) * FLAG_BIT_Z;
    }

    uint8_t flag_mask = (opcode->carry ? FLAG_BIT_C : 0) | (opcode->zs ? FLAG_BIT_Z | FLAG_BIT_S : 0) | FLAG_BIT_H;

    set_f(cpu, 0, (get_f(cpu, 0) & ~flag_mask) | (flags & flag_mask));
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

enum
{
    SCREEN_BASE = 0x2400,
    SCREEN_BITS_PER_PIXEL_COLUMN = 0x100,
    SCREEN_BYTES_PER_PIXEL_COLUMN = SCREEN_BITS_PER_PIXEL_COLUMN / CHAR_BIT,
    SCREEN_COLUMNS = 224,
    SCREEN_BYTES = SCREEN_BYTES_PER_PIXEL_COLUMN * SCREEN_COLUMNS,
};

void set_mem_impl(uint8_t *mem, uint16_t addr, uint8_t val)
{
    if (addr >= SCREEN_BASE && addr < SCREEN_BASE + SCREEN_BYTES)
    {
        printf("R %04x %02x\n", addr, val);
    }
    mem[addr] = val;
}

uint32_t _draw_simp_sprite_impl(uint8_t *mem, uint16_t counter, uint16_t *sprite_addr, uint16_t *screen_addr)
{
    printf("%s %u *sprite_addr:%04x *screen_addr:%04x\n", __func__, counter, *sprite_addr, *screen_addr);
    do
    {
        set_mem_impl(mem, *screen_addr, mem[*sprite_addr]);
        *screen_addr += SCREEN_BYTES_PER_PIXEL_COLUMN;
        ++*sprite_addr;
        --counter;
    } while(counter);
    return 0;
}

uint32_t _draw_simp_sprite(struct cpu *cpu)
{
    return _draw_simp_sprite_impl(cpu->mem, get_b(cpu, 0), cpu->cpu_state.regs + REG_DE, cpu->cpu_state.regs + REG_HL);
}

uint32_t _block_copy_impl(uint8_t *mem, uint16_t *dst, uint16_t *src, uint8_t *len)
{
    printf("%s *dst:%04x *src:%04x *len:%04x\n", __func__, *dst, *src, *len);
    do
    {
        set_mem_impl(mem, *dst, mem[*src]);
        ++*dst;
        ++*src;
        --*len;
    }
    while (*len);
    return 0;
}

uint32_t _block_copy(struct cpu *cpu) /* From DE addr to HL addr. */
{
    return _block_copy_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, cpu->cpu_state.regs + REG_DE, (uint8_t *)(cpu->cpu_state.regs + REG_BC) + 1);
}

uint32_t _draw_char_impl(uint8_t *mem, uint16_t *screen_addr, uint8_t character)
{
    uint16_t character_addr = character_set + 8 * character;

    _draw_simp_sprite_impl(mem, 8, &character_addr, screen_addr);
    return 0;
}

uint32_t _draw_char(struct cpu *cpu)
{
    return _draw_char_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_a(cpu, 0));
}

uint32_t _print_message_impl(uint8_t *mem, uint8_t length, uint16_t *message, uint16_t *screen_addr)
{
    printf("%s\n", __func__);
    for (uint8_t index = 0; index < length; ++index)
    {
        _draw_char_impl(mem, screen_addr, mem[*message + index]);
    }
    return 0;
}

uint32_t _print_message(struct cpu *cpu)
{
    return _print_message_impl(cpu->mem, get_c(cpu, 0), cpu->cpu_state.regs + REG_DE, cpu->cpu_state.regs + REG_HL);
}

enum
{
    CHAR_TABLE_OFFSET_OF_ZERO = 0x1a, /* Hop over letters A-Z. */
};
uint32_t _draw_digit_in_acc_impl(uint8_t *mem, uint16_t *screen_addr, uint8_t digit)
{
    printf("%s\n", __func__);
    return _draw_char_impl(mem, screen_addr, digit + CHAR_TABLE_OFFSET_OF_ZERO);
}

uint32_t _draw_digit_in_acc(struct cpu *cpu)
{
    return _draw_digit_in_acc_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_a(cpu, 0));
}

uint32_t _draw_hex_byte_impl(uint8_t *mem, uint16_t *screen_addr, uint8_t byte)
{
    printf("%s\n", __func__);
    uint32_t ret = 0;

    ret += _draw_digit_in_acc_impl(mem, screen_addr, byte >> 4 * 1 & 0x0f);
    ret += _draw_digit_in_acc_impl(mem, screen_addr, byte >> 4 * 0 & 0x0f);

    return 0;
}

uint32_t _draw_hex_byte(struct cpu *cpu)
{
    return _draw_hex_byte_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_a(cpu, 0));
}

uint32_t _draw_hex_word_impl(uint8_t *mem, uint16_t *screen_addr, uint16_t word)
{
    printf("%s\n", __func__);
    uint32_t ret = 0;

    ret += _draw_hex_byte_impl(mem, screen_addr, word >> 8 * 1 & 0xff);
    ret += _draw_hex_byte_impl(mem, screen_addr, word >> 8 * 0 & 0xff);

    return 0;
}

uint32_t _draw_hex_word(struct cpu *cpu)
{
    return _draw_hex_word_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_de(cpu, 0));
}

uint32_t _conv_to_scr_impl(uint16_t *val)
{
    uint16_t a = (*val >> 8 * 0 & 0xff);
    uint16_t b = (*val >> 8 * 1 & 0xff);

    *val = (0x2000 | (b * SCREEN_BYTES_PER_PIXEL_COLUMN + a / 8)) & 0x3fff;
    printf("%s %u %u %u %04x\n", __func__, b, a / 8, a, *val);

    return 0;
}

uint32_t _conv_to_scr(struct cpu *cpu)
{
    return _conv_to_scr_impl(cpu->cpu_state.regs + REG_HL);
}

struct desc
{
    uint16_t sprite_addr;
    uint16_t screen_loc;
    uint8_t sprite_bytes;
}__attribute__((packed));

struct desc read_desc_impl(uint8_t *mem, uint16_t desc_addr)
{
    struct desc desc = { };
    memcpy(&desc, mem + desc_addr, sizeof(desc));

    return desc;
}

uint32_t _read_desc(struct cpu *cpu)
{
    struct desc desc = read_desc_impl(cpu->mem, cpu->cpu_state.regs[REG_HL]);
    cpu->cpu_state.regs[REG_DE] = desc.sprite_addr;
    cpu->cpu_state.regs[REG_HL] = desc.screen_loc;
    set_b(cpu, 0, desc.sprite_bytes);
    return 0;
}

int screen_regression_mode;
int _clear_screen_impl(uint8_t *mem)
{
    if (screen_regression_mode)
    {
        for (uint16_t index = 0; index < SCREEN_BYTES; ++index)
        {
            set_mem_impl(mem, SCREEN_BASE + index, 0);
        }
    }
    else
    {
        memset(mem + SCREEN_BASE, 0, SCREEN_BYTES);
    }
    return 0;
}

uint32_t _clear_screen(struct cpu *cpu)
{
    return _clear_screen_impl(cpu->mem);
}

enum
{
    PLAYER_TWO_SCORE_COORD = 0x391c,
};

uint32_t _init_racks_direction_impl(uint8_t *mem)
{
    mem[p1ref_alien_dx] = mem[p2ref_alien_dx] = 2; /* Delta is right two pixels */

    if (mem[two_players])
    {
        assert(0);
    }

    return 0;
}

uint32_t _init_racks_direction(struct cpu *cpu)
{
    return _init_racks_direction_impl(cpu->mem);
}

uint32_t _alt_alien_sprites_impl(uint16_t *de) /* Fucksake why is this a subroutine? */
{
    *de += 0x30; /* Animates the aliens. Add nothing and they freeze.*/
    return 0;
}

uint32_t _alt_alien_sprites(struct cpu *cpu)
{
    return _alt_alien_sprites_impl(cpu->cpu_state.regs + REG_DE);
}

enum
{
    ROWS_OF_ALIENS = 5,
    ALIENS_PER_ROW = 0x0b,
    ALIENS = ROWS_OF_ALIENS * ALIENS_PER_ROW,
};

// Convert alien index in L to screen bit position in C,L.
// Return alien row index (converts to type) in D.
uint32_t _get_alien_coords_impl(uint8_t *mem, uint8_t *c, uint8_t *l, uint8_t *d)
{
//  ld d,000h                        ; 017a     16 00            ;  Row 0
    *d = 0;
//  ld a,l                           ; 017c     7d               ;  Hold onto alien index
    uint8_t a = *l;

//      ld hl,ref_alien_yr               ; 017d     21 09 20         ;  Get alien X ...
//      ld b,(hl)                        ; 0180     46               ;  ... to B
//      inc hl                           ; 0181     23               ;  Get alien y ...
//      ld c,(hl)                        ; 0182     4e               ;  ... to C
    uint8_t b = mem[ref_alien_yr];
    *c = mem[ref_alien_xr];

    printf("%s entry *l:%u mem[ref_alien_yr]:%u mem[ref_alien_xr]:%u ", __func__, *l, mem[ref_alien_yr], mem[ref_alien_xr]);

l0183h:
    if (a < ALIENS_PER_ROW) goto l0194h;
//      cp 00bh                          ; 0183     fe 0b            ;  Can we take a full row off of index?
//      jp m,l0194h                      ; 0185     fa 94 01         ;  No ... we have the row
//      sbc a,00bh                       ; 0188     de 0b            ;  Subtract off 11 (one whole row)
    a -= ALIENS_PER_ROW;
//      ld e,a                           ; 018a     5f               ;  Hold the new index
//      ld a,b                           ; 018b     78               ;  Add ...
//      add a,010h                       ; 018c     c6 10            ;  ... 16 to bit ...
//      ld b,a                           ; 018e     47               ;  ... position Y (1 row in rack)
    b += 0x10;
//      ld a,e                           ; 018f     7b               ;  Restore tallied index
//      inc d                            ; 0190     14               ;  Next row
    ++*d;
//      jp l0183h                        ; 0191     c3 83 01         ;  Keep skipping whole rows
    goto l0183h;

l0194h:
//      ld l,b                           ; 0194     68               ;  We have the LSB (the row)
    *l = b;

l0195h:
//      and a                            ; 0195     a7               ;  Are we in the right column?
//      ret z                            ; 0196     c8               ;  Yes ... X and Y are right
    if (!a) {
        printf("exit *c:%u *l:%u *d:%u\n", *c, *l, *d);
        return 0;
    }
//      ld e,a                           ; 0197     5f               ;  Hold index
//      ld a,c                           ; 0198     79               ;  Add ...
//      add a,010h                       ; 0199     c6 10            ;  ... 16 to bit ...
//      ld c,a                           ; 019b     4f               ;  ... position X (1 column in rack)
//      ld a,e                           ; 019c     7b               ;  Restore index
    *c += 0x10;
//      dec a                            ; 019d     3d               ;  We adjusted for 1 column
    --a;
//      jp l0195h                        ; 019e     c3 95 01         ;  Keep moving over column
    goto l0195h;

    return 0;
}

enum
{
    LO,
    HI
};
uint32_t _get_alien_coords(struct cpu *cpu)
{
    return _get_alien_coords_impl(cpu->mem, (uint8_t *)&cpu->cpu_state.regs[REG_BC] + LO, (uint8_t *)&cpu->cpu_state.regs[REG_HL] + LO, (uint8_t *)&cpu->cpu_state.regs[REG_DE] + HI);
}

uint32_t _add_delta_impl(uint8_t *mem, uint16_t addr, uint8_t dx, uint8_t *y)
{
    uint8_t dy = mem[addr + 1];  /* We loaded delta-x already ... skip over it */
    mem[addr + 2] += dx;
    *y = mem[addr + 3] += dy; /* Fail to do this and the aliens do not move across the screen. Clues for x and y which appear muddled in the comments. */

    return 0;
}

uint32_t _add_delta(struct cpu *cpu)
{
    return _add_delta_impl(cpu->mem, cpu->cpu_state.regs[REG_HL], cpu->cpu_state.regs[REG_BC] & 0xff, (uint8_t *)&cpu->cpu_state.regs[REG_AF] + HI);
}

uint32_t _copy_ram_mirror_impl(uint8_t *mem)
{
    enum
    {
        RAM_MIRROR_SIZE = 0xc0,
    };
    memcpy(mem + ram_start, mem + ram_mirror, RAM_MIRROR_SIZE);
    return 0;
}

uint32_t _copy_ram_mirror(struct cpu *cpu)
{
    return _copy_ram_mirror_impl(cpu->mem);
}

uint32_t _read_ply_shot(struct cpu *cpu)
{
    struct desc desc = read_desc_impl(cpu->mem, player_shot_desc);
    cpu->cpu_state.regs[REG_DE] = desc.sprite_addr;
    cpu->cpu_state.regs[REG_HL] = desc.screen_loc;
    set_b(cpu, 0, desc.sprite_bytes);
    return 0;
}

enum
{
    SHOT_STRUCTURE_SIZE = 0x0b,
};

uint32_t _to_shot_struct_impl(uint8_t *mem, uint8_t shot_pic_end_value, uint16_t shot_struct_addr)
{
    mem[shot_pic_end] = shot_pic_end_value;
    memcpy(mem + a_shot_status, mem + shot_struct_addr, SHOT_STRUCTURE_SIZE);
    return 0;
}

uint32_t _to_shot_struct(struct cpu *cpu)
{
    return _to_shot_struct_impl(cpu->mem, get_a(cpu, 0), cpu->cpu_state.regs[REG_DE]);
}

uint32_t _find_in_column_impl(uint8_t *mem, uint8_t column, int *found, uint8_t *alien_index)
{
    uint8_t index = column - 1;
    uint8_t *aliens_base_addr = mem + ((uint16_t)mem[player_data_msb] << 8);

    *found = 0;

    for (uint8_t row = 0; row < ROWS_OF_ALIENS; ++row, index += ALIENS_PER_ROW)
    {
        if (aliens_base_addr[index])
        {
            *found = 1;
            *alien_index = index;
            return 0;
        }
    }

    return 0;
}

uint32_t _find_in_column(struct cpu *cpu)
{
    int found = 0;
    uint8_t alien_index = 0;
    int ret = _find_in_column_impl(cpu->mem, get_c(cpu, 0), &found, &alien_index);

    if (found)
    {
        set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_C);
    }
    else
    {
        set_f(cpu, 0, get_f(cpu, 0) & ~FLAG_BIT_C);
    }

    set_l(cpu, 0, alien_index);

    return ret;
}

enum
{
    SAUCER_STRUCTURE_SIZE = 0x0a,
};

uint32_t _reinit_saucer_impl(uint8_t *mem)
{
    /* Doing a bit more than neccessary here ... The assembler looks silly. */
    memcpy(mem + saucer_start, mem + data_for_saucer, SAUCER_STRUCTURE_SIZE);
    return 0;
}

uint32_t _reinit_saucer(struct cpu *cpu)
{
    return _reinit_saucer_impl(cpu->mem);
}

enum
{
    ALIENS_COORD_OFFSET_IN_PLAYER_DATA = 0xfc,
};

uint32_t _get_alien_reference_ptr_impl(uint8_t *mem, uint16_t *ptr)
{
    *ptr = ((uint16_t)mem[player_data_msb] << 8) + ALIENS_COORD_OFFSET_IN_PLAYER_DATA;
    return 0;
}

uint32_t _get_alien_reference_ptr(struct cpu *cpu)
{
    return _get_alien_reference_ptr_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _get_ships_per_cred_impl(uint8_t *mem, uint8_t *val)
{
    *val = (dip2 & 3) + 3;
    return 0;
}

uint32_t _get_ships_per_cred(struct cpu *cpu)
{
    uint8_t val = 0;
    uint32_t ret = _get_ships_per_cred_impl(cpu->mem, &val);

    set_a(cpu, 0, val);

    return ret;
}

uint32_t _time_to_saucer_impl(uint8_t *mem)
{
    enum
    {
        FIRST_RACK_YR = 0x78,
        TILL_SAUCER_GAME_LOOPS = 0x600,
    };

    if (mem[ref_alien_yr] >= FIRST_RACK_YR) /* Aliens need to have moved down a row to make space for sauceri, before we even start the timer */
    {
        return 0;
    }

    uint16_t *till_saucer = (uint16_t *)(mem + till_saucer_lsb);

    if (*till_saucer == 0)
    {
        *till_saucer = TILL_SAUCER_GAME_LOOPS;
        mem[saucer_start] = 1;
    }

    --*till_saucer;
    return 0;
}

uint32_t _time_to_saucer(struct cpu *cpu)
{
    return _time_to_saucer_impl(cpu->mem);
}

uint32_t _alien_score_value_impl(uint8_t *mem, uint8_t row, uint16_t *value_addr)
{
    if (row < 2)
    {
        *value_addr = table_alien_score_val + 0;
    }
    else if (row < 4)
    {
        *value_addr = table_alien_score_val + 1;
    }
    else
    {
        *value_addr = table_alien_score_val + 2;
    }

    return 0;
}

uint32_t _alien_score_value(struct cpu *cpu) /* Why not put the result in a though? */
{
    return _alien_score_value_impl(cpu->mem, get_a(cpu, 0), cpu->cpu_state.regs + REG_HL);
}

uint32_t _cnvt_pix_number_impl(uint8_t *mem, uint16_t *val)
{
    port_op(0, 2, *val & 7); /* Set up the gpu (lol, a barrel shifter). Seems to affect the missiles most ... */
    _conv_to_scr_impl(val);

    return 0;
}

uint32_t _cnvt_pix_number(struct cpu *cpu)
{
    return _cnvt_pix_number_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _get_alien_state_ptr_impl(uint8_t *mem, uint8_t row, uint8_t col, uint16_t *alien_state_addr)
{
    *alien_state_addr = ((uint16_t)mem[player_data_msb] << 8) + row * ALIENS_PER_ROW + col - 1;
    return 0;
}

uint32_t _get_alien_state_ptr(struct cpu *cpu)
{
    return _get_alien_state_ptr_impl(cpu->mem, get_b(cpu, 0), get_c(cpu, 0), cpu->cpu_state.regs + REG_HL);
}

uint32_t _wrap_ref_impl(uint8_t *mem, int8_t *a, uint8_t *sixteens_count)
{
    do
    {
        ++*sixteens_count;
        *a += 0x10;
    }while (*a < 0);

    return 0;
}

uint32_t _wrap_ref(struct cpu *cpu)
{
    return _wrap_ref_impl(cpu->mem, (int8_t *)&cpu->cpu_state.regs[REG_AF] + HI, (uint8_t *)&cpu->cpu_state.regs[REG_BC] + LO);
}

uint32_t _sub_176dh(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

uint32_t _fleet_sound_off(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

uint32_t _check_handle_tilt(struct cpu *cpu) /* I do not think my laptop has accelerometers. */
{
    return 0;
}

struct print_struct
{
    uint16_t screen_coord;
    uint16_t message_addr;
}__attribute((packed));

uint32_t _read_print_struct_impl(uint8_t *mem, int *invalid, uint16_t *struct_addr, uint16_t *screen_coord, uint16_t *message_addr)
{
    *invalid = 0;

    if (mem[*struct_addr] == 0xff)
    {
        *invalid = 1;
        return 0;
    }

    struct print_struct *print_struct = (struct print_struct *)(mem + *struct_addr);
    *screen_coord = print_struct->screen_coord;
    *message_addr = print_struct->message_addr;

    printf("%s *struct_addr:%04x *screen_coord:%04x *message_addr:%04x\n", __func__, *struct_addr, *screen_coord, *message_addr);fflush(stdout);
    *struct_addr += sizeof(struct print_struct);

    return 0;
}

uint32_t _read_print_struct(struct cpu *cpu)
{
    int invalid = 0;
    int ret = _read_print_struct_impl(cpu->mem, &invalid, cpu->cpu_state.regs + REG_BC, cpu->cpu_state.regs + REG_HL, cpu->cpu_state.regs + REG_DE);

    if (invalid)
    {
        set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_C);
    }
    else
    {
        set_f(cpu, 0, get_f(cpu, 0) & ~FLAG_BIT_C);
    }

    return ret;
}

enum
{
    PLAYER_1_ADDR = 0x2100,
    PLAYER_1_ADDR_MSB = (PLAYER_1_ADDR >> 8) & 0xff,
    PLAYER_2_ADDR = 0x2200,
    PLAYER_2_ADDR_MSB = (PLAYER_2_ADDR >> 8) & 0xff,
};

uint32_t _get_player_alive_ptr_impl(uint8_t *mem, uint16_t *player_alive_ptr)
{
    switch (mem[player_data_msb]) /* Original checks the lowest bit, that seems royally fucked up. */
    {
        case PLAYER_1_ADDR_MSB:
            *player_alive_ptr = player2alive;
            break;
        case PLAYER_2_ADDR_MSB:
            *player_alive_ptr = player1alive;
            break;
        default:
            break;
    };
    return 0;
}

uint32_t _get_player_alive_ptr(struct cpu *cpu) /* Unused, and you are an idiot for implementing it ... */
{
    return _get_player_alive_ptr_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _cur_ply_alive_impl(uint8_t *mem, uint16_t *player_alive_ptr) /* Upside down version of get_player_alive_ptr? */
{
    switch (mem[player_data_msb]) /* Original checks the lowest bit, that seems royally fucked up. */
    {
        case PLAYER_1_ADDR_MSB:
            *player_alive_ptr = player1alive;
            break;
        case PLAYER_2_ADDR_MSB:
            *player_alive_ptr = player2alive;
            break;
        default:
            break;
    };
    return 0;
}

uint32_t _cur_ply_alive(struct cpu *cpu)
{
    return _cur_ply_alive_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _get_player_score_descriptor_impl(uint8_t *mem, uint16_t *addr) /* Upside down version of get_player_alive_ptr? */
{
    switch (mem[player_data_msb]) /* Original checks the lowest bit, that seems royally fucked up. */
    {
        case PLAYER_1_ADDR_MSB:
            *addr = player_one_score_desc;
            break;
        case PLAYER_2_ADDR_MSB:
            *addr = player_two_score_desc;
            break;
        default:
            break;
    };
    return 0;
}

uint32_t _get_player_score_descriptor(struct cpu *cpu)
{
    return _get_player_score_descriptor_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _get_delta_x_impl(uint8_t *mem, uint8_t *delta_x)
{
    if (mem[num_aliens] <= 1)
    {
        *delta_x = 3; /* Speed up when there is only one alien, but thos only applies for moving right... */
    }
    else
    {
        *delta_x = 2;
    }
    return 0;
}

uint32_t _get_delta_x(struct cpu *cpu)
{
    return _get_delta_x_impl(cpu->mem, (uint8_t *)&cpu->cpu_state.regs[REG_BC] + HI);
}

uint32_t _sound_bits3on(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

uint32_t _sound_bits3off(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

void init_aliens(uint8_t *mem, uint16_t aliens_addr)
{
    memset(mem + aliens_addr, 1, ALIENS);
}

uint32_t _init_aliens_player_one(struct cpu *cpu)
{
    init_aliens(cpu->mem, PLAYER_1_ADDR);
    return 0;
}

uint32_t _init_aliens_player_two(struct cpu *cpu)
{
    init_aliens(cpu->mem, PLAYER_2_ADDR);
    return 0;
}

uint32_t _draw_score_head_impl(uint8_t *mem, uint16_t *screen_addr) /* Duff? */
{
    enum
    {
        MSG_SCORE_HEADER_LENGTH = 0x1c,
    };
    *screen_addr = 0x241e;
    uint16_t msg = msg_score_header;
    _print_message_impl(mem, MSG_SCORE_HEADER_LENGTH, &msg, screen_addr);
    return 0;
}

struct score_descriptor
{
    uint16_t value;
    uint16_t screen_coord;
}__attribute((packed));

uint32_t _draw_score_impl(uint8_t *mem, uint16_t score_descriptor_addr)
{
    struct score_descriptor *score_descriptor = (struct score_descriptor *)(mem + score_descriptor_addr);
    uint16_t screen_coord = score_descriptor->screen_coord;

    return _draw_hex_word_impl(mem, &screen_coord, score_descriptor->value);
}

uint32_t _draw_score(struct cpu *cpu)
{
    return _draw_score_impl(cpu->mem, cpu->cpu_state.regs[REG_HL]);
}

uint32_t _draw_score_head(struct cpu *cpu)
{
    return _draw_score_head_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _print_player_one_score_impl(uint8_t *mem)
{
    return _draw_score_impl(mem, player_one_score_desc);
}

uint32_t _print_player_one_score(struct cpu *cpu)
{
    return _print_player_one_score_impl(cpu->mem);
}

uint32_t _print_player_two_score_impl(uint8_t *mem)
{
    return _draw_score_impl(mem, player_two_score_desc);
}

uint32_t _print_player_two_score(struct cpu *cpu)
{
    return _print_player_two_score_impl(cpu->mem);
}

uint32_t _print_high_score_impl(uint8_t *mem)
{
    return _draw_score_impl(mem, high_score_desc);
}

uint32_t _print_high_score(struct cpu *cpu)
{
    return _print_high_score_impl(cpu->mem);
}

uint32_t _print_credit_label_impl(uint8_t *mem)
{
    enum
    {
        MSG_CREDIT_LENGTH = 7,
        MSG_CREDIT_COORDS = 0x3501,
    };
    uint16_t screen_addr = MSG_CREDIT_COORDS;
    uint16_t msg = msg_credit;
    return _print_message_impl(mem, MSG_CREDIT_LENGTH, &msg, &screen_addr);
}

uint32_t _print_credit_label(struct cpu *cpu)
{
    return _print_credit_label_impl(cpu->mem);
}

uint32_t _draw_num_credits_impl(uint8_t *mem)
{
    enum
    {
        NUM_CREDITS_COORD = 0x3c01,
    };
    uint16_t screen_addr = NUM_CREDITS_COORD;
    return _draw_hex_byte_impl(mem, &screen_addr, mem[num_coins]);
}

uint32_t _draw_num_credits(struct cpu *cpu)
{
    return _draw_num_credits_impl(cpu->mem);
}

uint32_t _enable_game_tasks_impl(uint8_t *mem)
{
    mem[suspend_play] = 1; /* Wut? */
    return 0;
}

uint32_t _enable_game_tasks(struct cpu *cpu)
{
    return _enable_game_tasks_impl(cpu->mem);
}

uint32_t _disable_game_tasks_impl(uint8_t *mem)
{
    mem[suspend_play] = 0; /* Wut? */
    return 0;
}

uint32_t _disable_game_tasks(struct cpu *cpu)
{
    return _disable_game_tasks_impl(cpu->mem);
}

uint32_t _copy_rom_to_ram_impl(uint8_t *mem)
{
    memcpy(mem + ram_start, mem + ram_mirror, 0x100);
    return 0;
}

uint32_t _copy_rom_to_ram(struct cpu *cpu)
{
    return _copy_rom_to_ram_impl(cpu->mem);
}

uint32_t _flag_player_hit_impl(uint8_t *mem, int *player_hit)
{
    *player_hit = mem[player_alive] == 0xff;
    return 0;
}

uint32_t _flag_player_hit(struct cpu *cpu)
{
    int player_hit = 0;
    uint32_t ret = _flag_player_hit_impl(cpu->mem, &player_hit);

    if (player_hit)
    {
        set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_Z);
    }
    else
    {
        set_f(cpu, 0, get_f(cpu, 0) & ~FLAG_BIT_Z);
    }
    return ret;
}

uint32_t _get_saucer_descriptor_impl(uint8_t *mem, uint16_t *sprite_addr, uint8_t *sprite_bytes, uint16_t *screen_addr)
{
    struct desc desc = read_desc_impl(mem, saucer_pri_loc_lsb);
    *sprite_addr = desc.sprite_addr;
    *sprite_bytes = desc.sprite_bytes;

    uint16_t val = desc.screen_loc;
    _conv_to_scr_impl(&val);
    *screen_addr = val;

    return 0;
}

uint32_t _get_saucer_descriptor(struct cpu *cpu)
{
    return _get_saucer_descriptor_impl(cpu->mem, cpu->cpu_state.regs + REG_DE, (uint8_t *)&cpu->cpu_state.regs[REG_BC] + HI, cpu->cpu_state.regs + REG_HL);
}

uint32_t _ini_splash_ani_impl(uint8_t *mem, uint16_t *src_addr)
{
    enum
    {
        SPLASH_ANI_LENGTH = 0x0c,
    };
    uint16_t dst = splash_an_form;
    uint8_t length = SPLASH_ANI_LENGTH;

    _block_copy_impl(mem, &dst, src_addr, &length);
    return 0;
}

uint32_t _ini_splash_ani(struct cpu *cpu)
{
    return _ini_splash_ani_impl(cpu->mem, cpu->cpu_state.regs + REG_DE);
}

uint32_t _print_to_mid_screen_impl(uint8_t *mem, uint16_t msg_addr) /* Poorly done assembler ... */
{
    enum
    {
        MID_SCREEN_ADDR = 0x2b14,
        MSG_SPACE_INVADERS_LENGTH = 0xf,

    };
    uint16_t screen_addr = MID_SCREEN_ADDR;
    return _print_message_impl(mem, MSG_SPACE_INVADERS_LENGTH, &msg_addr, &screen_addr);
}

uint32_t _print_to_mid_screen(struct cpu *cpu)
{
    return _print_to_mid_screen_impl(cpu->mem, cpu->cpu_state.regs[REG_DE]);
}

uint32_t _suspend_game_tasks_impl(uint8_t *mem)
{
    _disable_game_tasks_impl(mem);
    _draw_num_credits_impl(mem);
    _print_credit_label_impl(mem);
    return 0;
}

uint32_t _suspend_game_tasks(struct cpu *cpu)
{
    return _suspend_game_tasks_impl(cpu->mem);
}

uint32_t _get_player_data_ptr_impl(uint8_t *mem, uint16_t *player_data_addr)
{
    *player_data_addr = (uint16_t)mem[player_data_msb] << 8;
    return 0;
}

uint32_t _get_player_data_ptr(struct cpu *cpu)
{
    return _get_player_data_ptr_impl(cpu->mem, cpu->cpu_state.regs + REG_HL);
}

uint32_t _draw_sprite_impl(uint8_t *mem, uint16_t *hl, uint16_t sprite_addr, uint8_t sprite_length)
{
    _cnvt_pix_number_impl(mem, hl);
    uint16_t save_hl = *hl;

    while (sprite_length--)
    {
        port_op(0, 4, mem[sprite_addr]); /* Data to shift register. */
        mem[*hl + 0] = port_ip(0, 3);

        port_op(0, 4, 0); /* Data to shift register. */
        mem[*hl + 1] = port_ip(0, 3);

        *hl += SCREEN_BYTES_PER_PIXEL_COLUMN;

        ++sprite_addr;
    }

    *hl = save_hl;
    return 0;
}

uint32_t _draw_sprite(struct cpu *cpu)
{
    return _draw_sprite_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, cpu->cpu_state.regs[REG_DE], get_b(cpu, 0));
}

uint32_t _erase_shifted_impl(uint8_t *mem, uint16_t *hl, uint16_t sprite_addr, uint8_t sprite_length)
{
    _cnvt_pix_number_impl(mem, hl);
//  uint16_t save_hl = *hl;

    while (sprite_length--)
    {
        port_op(0, 4, mem[sprite_addr]); /* Data to shift register. */
        mem[*hl + 0] &= ~port_ip(0, 3);

        port_op(0, 4, 0); /* Data to shift register. */
        mem[*hl + 1] &= ~port_ip(0, 3);

        *hl += SCREEN_BYTES_PER_PIXEL_COLUMN;

        ++sprite_addr;
    }

//  *hl = save_hl;
    return 0;
}

uint32_t _erase_shifted(struct cpu *cpu)
{
    return _erase_shifted_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, cpu->cpu_state.regs[REG_DE], get_b(cpu, 0));
}

uint32_t _draw_wide_sprite_impl(uint8_t *mem, uint16_t *hl, uint16_t sprite_addr)
{
    enum
    {
        WIDE_SPRITE_LENGTH = 0x10,
    };
    _draw_simp_sprite_impl(mem, WIDE_SPRITE_LENGTH, &sprite_addr, hl);
    return 0;
}

uint32_t _draw_wide_sprite(struct cpu *cpu)
{
    return _draw_wide_sprite_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, cpu->cpu_state.regs[REG_DE]);
}

uint32_t _erase_simple_sprite_impl(uint8_t *mem, uint16_t *hl, uint8_t sprite_length)
{
    _cnvt_pix_number_impl(mem, hl);
    while (sprite_length--)
    {
        mem[*hl + 0] = 0;
        mem[*hl + 1] = 0;

        *hl += SCREEN_BYTES_PER_PIXEL_COLUMN;
    }
    return 0;
}

uint32_t _erase_simple_sprite(struct cpu *cpu)
{
    return _erase_simple_sprite_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_b(cpu, 0));
}

uint32_t _read_inputs_impl(uint8_t *mem, uint8_t *val)
{
    *val = port_ip(0, mem[player_data_msb] & 0x01 ? 1 : 2);
    return 0;
}

uint32_t _read_inputs(struct cpu *cpu)
{
    return _read_inputs_impl(cpu->mem, (uint8_t *)&cpu->cpu_state.regs[REG_AF] + HI);
}

uint32_t _shot_sound_impl(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

uint32_t _shot_sound(struct cpu *cpu) /* Full of sound and fury. Signifying nothing. */
{
    return 0;
}

uint32_t _clear_play_field_impl(uint8_t *mem)
{
    uint16_t screen_addr = 0x2402; /* Third from left, top of screen. */

    for (;;)
    {
        mem[screen_addr++] = 0;
        if ((screen_addr & (SCREEN_BYTES_PER_PIXEL_COLUMN - 1)) == 0x1c)
        {
            screen_addr += 6;
        }

        if (screen_addr >= 0x4000)
        {
            break;
        }
    }

    return 0;
}

uint32_t _clear_play_field(struct cpu *cpu)
{
    return _clear_play_field_impl(cpu->mem);
}

uint32_t _clear_playfield_taito_msg_impl(uint8_t *mem)
{
    _clear_play_field_impl(mem);
    enum
    {
        SCREEN_ADDR = 0x2803,
        MSG_LENGTH = 0x13,

    };
    uint16_t screen_addr = SCREEN_ADDR;
    uint16_t msg_addr = msg_taito_corporation;
    return _print_message_impl(mem, MSG_LENGTH, &msg_addr, &screen_addr);
    return 0;
}

uint32_t _clear_playfield_taito_msg(struct cpu *cpu)
{
    return _clear_playfield_taito_msg_impl(cpu->mem);
}

uint32_t _speed_shots_impl(uint8_t *mem)
{
    if (mem[num_aliens] > 8)
    {
    }
    else
    {
        mem[alien_shot_delta] = 0xfb;
    }
    return 0;
}

uint32_t _speed_shots(struct cpu *cpu)
{
    return _speed_shots_impl(cpu->mem);
}

uint32_t _draw_status_impl(uint8_t *mem)
{
    _clear_screen_impl(mem);
    uint16_t discard = 0;
    _draw_score_head_impl(mem, &discard);
    _print_player_one_score_impl(mem);
    _print_player_two_score_impl(mem);
    _print_high_score_impl(mem);
    _print_credit_label_impl(mem);
    _draw_num_credits_impl(mem);

    return 0;
}

uint32_t _draw_status(struct cpu *cpu)
{
    return _draw_status_impl(cpu->mem);
}

uint32_t _fill_screen_row_impl(uint8_t *mem, uint16_t *screen_addr, uint16_t elems, uint8_t value)
{
    for (uint16_t index = 0; index < elems; ++index)
    {
        mem[*screen_addr] = value;
        *screen_addr += SCREEN_BYTES_PER_PIXEL_COLUMN;
    }
    return 0;
}

uint32_t _fill_screen_row(struct cpu *cpu)
{
    return _fill_screen_row_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_b(cpu, 0), get_a(cpu, 0));
}

uint32_t _clear_small_sprite(struct cpu *cpu)
{
    return _fill_screen_row_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, get_b(cpu, 0), 0);
}

uint32_t _check_column_impl(uint8_t *mem, uint16_t *screen_addr, int *clear)
{
    *clear = 1;
    enum
    {
        BYTES_TO_CHECK = 0x17,
    };

    for (uint16_t index = 0; index < BYTES_TO_CHECK; ++index)
    {
        if (mem[*screen_addr])
        {
            *clear = 0;
        }
        ++*screen_addr;
    }
    return 0;
}

uint32_t _check_column(struct cpu *cpu)
{
    int clear = 0;
    uint32_t ret = _check_column_impl(cpu->mem, cpu->cpu_state.regs + REG_HL, &clear);

    if (!clear)
    {
        set_f(cpu, 0, get_f(cpu, 0) | FLAG_BIT_C);
    }
    else
    {
        set_f(cpu, 0, get_f(cpu, 0) & ~FLAG_BIT_C);
    }

    return ret;
}

#if 0
uint32_t _template_impl(uint8_t *mem)
{
    return 0;
}

uint32_t _template(struct cpu *cpu)
{
    return _template_impl(cpu->mem);
}

#endif

#define MAP_CIMPL(F) [F] = _ ## F
#define _________(F) [F] = 0
uint32_t (*cimpl[0x10000])(struct cpu *cpu) = {
    MAP_CIMPL(draw_simp_sprite),
    MAP_CIMPL(block_copy),
    MAP_CIMPL(draw_char),
    MAP_CIMPL(print_message),
    MAP_CIMPL(draw_digit_in_acc),
    MAP_CIMPL(draw_hex_byte),
    MAP_CIMPL(draw_hex_word),
    MAP_CIMPL(conv_to_scr),
    MAP_CIMPL(read_desc),
    MAP_CIMPL(clear_screen),

    /* leaves */

    MAP_CIMPL(init_racks_direction),
    MAP_CIMPL(alt_alien_sprites),
    MAP_CIMPL(get_alien_coords),
    MAP_CIMPL(add_delta),
    MAP_CIMPL(copy_ram_mirror),
    MAP_CIMPL(read_ply_shot),
    MAP_CIMPL(to_shot_struct),
    MAP_CIMPL(find_in_column),
    MAP_CIMPL(reinit_saucer),
    MAP_CIMPL(get_alien_reference_ptr),
    MAP_CIMPL(get_ships_per_cred),
    MAP_CIMPL(time_to_saucer),
    MAP_CIMPL(alien_score_value),
    MAP_CIMPL(cnvt_pix_number),
    MAP_CIMPL(get_alien_state_ptr),
    MAP_CIMPL(wrap_ref),
    MAP_CIMPL(sub_176dh),
    MAP_CIMPL(fleet_sound_off),
    MAP_CIMPL(check_handle_tilt),
    MAP_CIMPL(read_print_struct),
    MAP_CIMPL(get_player_alive_ptr),
    MAP_CIMPL(get_delta_x),
    MAP_CIMPL(sound_bits3on),
    MAP_CIMPL(init_aliens_player_one),
    MAP_CIMPL(init_aliens_player_two),

    MAP_CIMPL(draw_score_head),
    MAP_CIMPL(print_player_one_score),
    MAP_CIMPL(print_player_two_score),
    MAP_CIMPL(print_high_score),
    MAP_CIMPL(print_credit_label),
    MAP_CIMPL(draw_num_credits),

    MAP_CIMPL(enable_game_tasks),
    MAP_CIMPL(disable_game_tasks),
    MAP_CIMPL(sound_bits3off),

    /* Next leaves, ordered by difficulty. */

    _________(wait_on_delay), /* Tricky, we want the ISR to run but we are in CIMPL ... think harder. */
    _________(one_sec_delay), /* Tricky, we want the ISR to run but we are in CIMPL ... think harder. */
    _________(two_sec_delay), /* Tricky, we want the ISR to run but we are in CIMPL ... think harder. */

    MAP_CIMPL(copy_rom_to_ram),
    MAP_CIMPL(flag_player_hit),
    MAP_CIMPL(get_saucer_descriptor),
    MAP_CIMPL(ini_splash_ani),
    MAP_CIMPL(print_to_mid_screen), /* Should use print_message_del but we cannot have nice things yet. */
    MAP_CIMPL(suspend_game_tasks),
    MAP_CIMPL(get_player_data_ptr),
    MAP_CIMPL(draw_sprite),
    MAP_CIMPL(erase_shifted),
    MAP_CIMPL(draw_wide_sprite),
    MAP_CIMPL(erase_simple_sprite),
    MAP_CIMPL(read_inputs),
    MAP_CIMPL(shot_sound),
    MAP_CIMPL(clear_play_field),
    MAP_CIMPL(clear_playfield_taito_msg),
    MAP_CIMPL(cur_ply_alive),
    MAP_CIMPL(get_player_score_descriptor),
    MAP_CIMPL(speed_shots),
    MAP_CIMPL(draw_status),
    MAP_CIMPL(fill_screen_row),
    MAP_CIMPL(clear_small_sprite),
    MAP_CIMPL(check_column),
    _________(cnt16s),
    _________(comp_yto_beam),
    _________(draw_score),
    _________(ctrl_saucer_sound),
    _________(control_isr_splash_from_acc),
    _________(draw_shield_pl1),
    _________(draw_shield_pl2),
    _________(restore_shields),
    _________(score_for_alien),
    _________(player_shot_hit),
    _________(init_rack),
    _________(time_fleet_sound),
    _________(plr_fire_or_demo),
    _________(draw_spr_collision),
    _________(fleet_delay_ex_ship),

    _________(animate),
    _________(print_message_del),
    _________(sub_189eh),
};

int interpreter_only;
uint32_t cimpl_wrapper(struct cpu *cpu, uint32_t duration)
{
    uint32_t clks = duration;
    if (!interpreter_only && cimpl[get_pc(cpu, 0)])
    {
        printf("here\n");
        clks = (cimpl[get_pc(cpu, 0)])(cpu);

        uint16_t sp = get_sp(cpu, 0);
        uint16_t lo = cpu->get_mem(cpu, sp + 0);
        uint16_t hi = cpu->get_mem(cpu, sp + 1);
        set_sp(cpu, 0, sp + 2);

        set_pc(cpu, 0, hi << 8 | lo << 0);
        cpu->next = get_pc(cpu, 0);
        cpu->jump = get_pc(cpu, 0);

        ret(cpu);
    }
    return clks;
}

uint32_t step(struct cpu *cpu)
{
    uint16_t pc = get_pc(cpu, 0);
    uint8_t op = cpu->get_mem(cpu, pc);
    const struct opcode *opcode = opcodes + op;

    cpu->inat = pc;
    cpu->next = 0;
    cpu->jump = 0;
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
                    cpu->next = pc + opcode->size;
                    cpu->jump = get_pc(cpu, 0);

                    cpu->clk[cpu->intr] += opcode->slow;

                    call(cpu);
                    return cimpl_wrapper(cpu, opcode->slow);
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
                    cpu->next = pc + opcode->size;
                    cpu->jump = get_pc(cpu, 0);

                    cpu->clk[cpu->intr] += opcode->slow;

                    if (op == 0xe9)
                    {
                        call(cpu);
                    }
                    return cimpl_wrapper(cpu, opcode->slow);
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
                cpu->next = pc + opcode->size;
                cpu->jump = get_pc(cpu, 0);

                cpu->clk[cpu->intr] += opcode->slow;
                return cimpl_wrapper(cpu, opcode->slow);
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
                    cpu->next = pc + opcode->size;
                    cpu->jump = get_pc(cpu, 0);

                    cpu->clk[cpu->intr] += opcode->slow;

                    ret(cpu);
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
    cpu->next = get_pc(cpu, 0);
    cpu->jump = get_pc(cpu, 0);

    cpu->clk[cpu->intr] += opcode->fast;
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

        cpu->intr = 1;

        set_pc(cpu, 0, addr);
        cpu->next = link;
        cpu->jump = get_pc(cpu, 0);

        cpu->inat = link;

        set_ie(cpu, 0, 0);

        cpu->sub_depth_intr = cpu->sub_depth;

        call(cpu);

        for (int trace_reg = 0; trace_reg < TRACES; ++trace_reg)
        {
            cpu->setat[cpu->intr][trace_reg] = (struct setat) {
                .inat = cpu->inat,
                .func = cpu->sub_stack[cpu->sub_depth - 1].inat,
                .call = cpu->call,
                .sub_depth = cpu->sub_depth,
            };
        }
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

void run(struct cpu *cpu, int cycles)
{
    while (cycles > 0)
    {
        cycles -= step(cpu);

        const struct opcode *opcode = opcodes + cpu->get_mem(cpu, cpu->inat);
        uint16_t sp = get_sp(cpu, 0);
        static int last_sub_depth;
        static uint16_t last_intr;
        int ie = get_ie(cpu, 0);

        switch (cpu->inat)
        {
            case 0x0abc:
            case 0x01ce:
                ret(cpu);
        }

        if (cpu->inat == 0x0087)
        {
            cpu->intr = 0;
        }

        if (screen_regression_mode && cpu->inat == 0x0bc3)
        {
            exit(0);
        }

        int sub_depth_altered = last_sub_depth != cpu->sub_depth;
        int interrupt_occurred = !last_intr && cpu->intr;
        int interrupt_returns = last_intr && !cpu->intr;
        if (sub_depth_altered)
        {
            printf("%-32s %s ", interrupt_occurred ? "INTERRUPT" : opcode->dasm, interrupt_returns ? "IRET" : "    ");

            printf("inat:%04x next:%04x jump:%04x sp:%04x sub_depth:%d ie:%d intr:%d ", cpu->inat, cpu->next, cpu->jump, sp, cpu->intr ? cpu->sub_depth - cpu->sub_depth_intr : cpu->sub_depth, ie, cpu->intr);

            for (int i = -2; i <= 2; ++i)
            {
                printf("%04x ", *(uint16_t *)(cpu->mem + sp + i * 2));
            }

            printf("\n");
        }

        last_sub_depth = cpu->sub_depth;
        last_intr = cpu->intr;
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

uint8_t get_mem(struct cpu *cpu, uint16_t addr)
{
    cpu->coverage[cpu->intr][addr] = 1;
    return cpu->mem[addr];
}

void set_mem(struct cpu *cpu, uint16_t addr, uint8_t val)
{
    if (addr >= SCREEN_BASE && addr < SCREEN_BASE + SCREEN_BYTES)
    {
        printf("R %04x %02x\n", addr, val);
    }
    cpu->mem[addr] = val;
}

void init(struct cpu *cpu, uint8_t *mem)
{
    memset(cpu, 0, sizeof *cpu);

    cpu->mem = mem;
    cpu->get_mem = get_mem;
    cpu->set_mem = set_mem;
    cpu->port_ip = port_ip;
    cpu->port_op = port_op;

    cpu->cpu_state.regs[REG_AF] = 0x0002;
    cpu->cpu_state.regs[REG_SP] = 0xF000;
    cpu->cpu_state.regs[REG_PC] = 0x0001;
}

#include <stdio.h>
#include <SDL2/SDL.h>

struct machine
{
    SDL_Renderer *renderer;
    SDL_Texture *texture;
};

struct machine *machine;

void render(uint8_t *mem)
{
    uint16_t vram_base = SCREEN_BASE;
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

char *save;
void save_core(void)
{
    FILE *f = fopen(save, "w");
    if (fwrite(cpu.mem, 0x10000, 1, f) != 1)
    {
        assert(0);
    }
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
                    case SDLK_q:
                        printf("\n");
                        for (unsigned addr = 0; addr < sizeof(cpu.coverage[0]); ++addr)
                        {
                            printf("coverage %04x %d %d %d\n", addr, cpu.coverage[0][addr], cpu.coverage[1][addr], addr);
                        }
                        exit(0);
                        break;
                    case SDLK_s:
                        if (save)
                        {
                            save_core();
                            exit(0);
                        }
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

struct regval
{
    uint16_t af;
    uint16_t bc;
    uint16_t de;
    uint16_t hl;
    uint16_t sp;
    uint16_t pc;
};

void init_regs(struct cpu *cpu, struct regval *regval)
{
    set_af(cpu, 0, regval->af);
    set_bc(cpu, 0, regval->bc);
    set_de(cpu, 0, regval->de);
    set_hl(cpu, 0, regval->hl);
    set_sp(cpu, 0, regval->sp);
    set_pc(cpu, 0, regval->pc);
}

int main(int argc, char *argv[])
{
    char *load = 0;

    for (;;)
    {
        int opt = getopt(argc, argv, "l:s:ri");

        if (opt == -1)
        {
            break;
        }

        switch (opt)
        {
            case 'l':
                load = optarg;
                break;
            case 's':
                save = optarg;
                break;
            case 'r':
                screen_regression_mode = 1;
                break;
            case 'i':
                interpreter_only = 1;
                break;
            default: /* '?' */
                printf("bad arg %c\n", opt);
                exit(EXIT_FAILURE);
        }
    }

    printf("Keys:\n");
    printf("    Left Arrow:  Left.\n");
    printf("    Right Arrow: Right.\n");
    printf("    z:           Fire.\n");
    printf("    x:           Press after coin insertion to start.\n");
    printf("    c:           Coin insertion! Press twice for two player.\n");
    printf("    q:           Quit.\n");

    machine = init_machine();

    init(&cpu, calloc(0x10000, 1));

    if (load)
    {
        FILE *f = fopen(load, "r");
        assert(f);

        if (fread(cpu.mem, 0x10000, 1, f) != 1)
        {
            assert(f);
        }

        struct regval regval = {
            .de = sprite_player,
            .bc = 0x1000,
            .hl = 0x0208,
            .sp = 0x2400,
            .pc = 0,
        };

        init_regs(&cpu, &regval);

        printf("get_h(&cpu, 0):%02x\n", get_h(&cpu, 0));
        printf("get_l(&cpu, 0):%02x\n", get_l(&cpu, 0));

        cpu.mem[0] = 0xCD;
        cpu.mem[1] = conv_to_scr >> 0 * 8 & 0xff;
        cpu.mem[2] = conv_to_scr >> 1 * 8 & 0xff;

        memset(cpu.mem + 0x2400, 0, 0x4000 - 0x2400);

        uint32_t cycles = 0;
        for (;;)
        {
            cycles += step(&cpu);

            printf("pc:%04x sp:%04x\n", get_pc(&cpu, 0), get_sp(&cpu, 0));
            dump();

            if (get_sp(&cpu, 0) == 0x2400)
            {
                break;
            }
        }

        exit(0);

        if (0)
        {
            render(cpu.mem);

            for (;;)
            {
                get_input();
            }
        }
    }
    else
    {
        for (int i = 0; i < 4; i++)
        {
            char *bank_name[] = { "invaders.h", "invaders.g", "invaders.f", "invaders.e" };

            FILE *fp = fopen(bank_name[i], "rb");
            if (!fp)
            {
                return 0;
            }
            if (fread(cpu.mem + (i * 0x0800), 1, 0x0800, fp) != 0x0800)
            {
                return 0;
            }
            fclose(fp);
        }

        cpu.mem[0] = 0xc3;

        for (;;)
        {
            run(&cpu, 17066);
            intr(&cpu, 8);
            render(cpu.mem);
            run(&cpu, 17066);
            intr(&cpu, 16);
            get_input();
            SDL_Delay(15);

        }
    }

    return 1;
}
