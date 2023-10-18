#lang brag

parser-syntax : rule+

rule : NON-TERMINAL COLON alteration SEMICOLON

alteration : expansion (ALTERATION expansion)*
expansion : (non-terminal | terminal)*

non-terminal : NON-TERMINAL [STAR] [QUESTION]
terminal : TERMINAL [STAR] [QUESTION]

