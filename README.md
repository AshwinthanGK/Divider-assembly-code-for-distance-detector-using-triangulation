# AVR Fixed-Point Trig & Math (ATmega328P Assembly)

This repository contains an ATmega328P AVR assembly program that computes sin(θ) and cos(θ) using a precomputed sine lookup table (LUT) and evaluates a composite trigonometric expression using **fixed-point arithmetic**. The implementation includes an 8×8→16 multiply (`mul`) path and a custom 16-bit dividend / 8-bit divisor division routine for fixed-point scaling.

## Key Features
- Sine LUT: Precomputed sine values scaled to **0–255** for angles 0°–180°
- Cosine from sine: `cos(θ)` derived using angle shifting around 90°
- Fixed-point math:
  - 8-bit scaled trig values (0–255)
  - 16-bit intermediate products (`mul`, stored in high/low registers)
  - Custom division routine for ratio-like computations
- Written for ATmega328P (`m328pdef.inc`), compatible with Atmel Studio 7 / AVR toolchain

## Target
- MCU: ATmega328P
- Toolchain: Atmel Studio 7 (AVR assembler)
- Data format: 8-bit LUT scale (0→0, 1→255)

## Files
- `AssemblerApplication1.asm` – main program, LUT, trig subroutines, and fixed-point division

## How it Works 
1. Load angles (degrees) into registers
2. Compute `sin(θ)` by indexing into the LUT via `LPM`
3. Compute `cos(θ)` by transforming the angle and reusing the LUT
4. Evaluate the expression using:
   - `mul` for products (8×8 → 16-bit)
   - custom fixed-point division for scaling
5. Result is available in output registers (documented in code comments)


## Register Map 
- `R16` : angle input / temp / loop counters
- `R19` : sin(theta1)
- `R18` : sin(theta2) / divisor in division stage
- `R14` : cos(theta1)
- `R17` : cos(theta2)
- `R21:R20` : 16-bit dividend (mul output)
- `R22:R23` : 16-bit quotient / accumulator (varies by stage)

## Author
Ashwin (gkash)
