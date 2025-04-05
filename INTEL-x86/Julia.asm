; https://rosettacode.org/wiki/Julia_set#C - algortihm
; https://www.ired.team/miscellaneous-reversing-forensics/windows-kernel-internals/windows-x64-calling-convention-stack-frame
; Microsoft x64 calling convention
; pixels (uint8_t*) is accessed through the RCX
; width (int) is accesed through the RDX
; height (int) is accesed through the R8
; thresholdRadius (double) is accesed through the XMM3
; cReal, cImage, centerX, centerY, zoom (double) are accesed through the stack [0x28] to [0x48]

    section .text
    global generateJulia

generateJulia:
    ; Initialization variables
    ; rcx = uint8_t* pixels
    ; rdx = width
    ; r8 = height
    mov r9, [rsp + 0x50]    ; r9 = colors
    mov r10, [rsp + 0x58]   ; r10 = isColored
    movsd xmm0, [rsp + 0x28]    ; xmm0 = cReal
    movsd xmm1, [rsp + 0x30]    ; xmm1 = cImage
    movsd xmm2, [rsp + 0x38]    ; xmm2 = ceterX
    ; xmm3 = thresholdRadius
    movsd xmm4, [rsp + 0x40]    ; xmm4 = ceterY
    movsd xmm5, [rsp + 0x48]    ; xmm5 = zoom

    ;Prologue
    push rbp
    mov rbp, rsp

    ; r12 and r13 has to be preserved : https://www.cs.uaf.edu/2017/fall/cs301/reference/x86_64.html
    push r12
    push r13

    mov r12, r9
    mov r13, r10
    xor r9, r9      ; x = 0
    xor r10, r10    ; y = 0


    ; Fractal Julia algorithm
loop_x:
    ; real part compute
    cvtsi2sd xmm6, r9   ; real part = double(current x)
    subsd xmm6, xmm2    ; x -= centerX
    addsd xmm6, xmm6    ; x *= 2
    mulsd xmm6, xmm3    ; x *= thresholdRadius
    cvtsi2sd xmm7, rdx  ; xmm7 = double(width)
    mulsd xmm7, xmm5    ; xmm7 = width * zoom
    divsd xmm6, xmm7    ; real part = (x - centerX) * 2 * thresholdRadius / (width * zoom)

    ; imaginary part compute
    cvtsi2sd xmm8, r10  ; imaginary part = double(current y)
    subsd xmm8, xmm4    ; y -= centerY
    addsd xmm8, xmm8    ; y *= 2
    mulsd xmm8, xmm3    ; y *= thresholdRadius
    cvtsi2sd xmm9, r8   ; xmm9 = double(height)
    mulsd xmm9, xmm5    ; xmm9 = height * zoom
    divsd xmm8, xmm9    ; image part = (y - centerY) * thresholdRadius * 2 / (height * zoom)
    
    xor r11, r11        ; iteration = 0

iterate_fractal:
    cmp r11, 255
    je store_byte
    inc r11 ; iteration +=1

    ; New image part compute
    movsd xmm10, xmm6   ; xmm10 = real part
    mulsd xmm10, xmm8   ; xmm10 *= image part
    addsd xmm10, xmm10  ; xmm10 *= 2
    addsd xmm10, xmm1   ; xmm10 += cReal

    ; New real part compute
    movsd xmm11, xmm6   ; xmm11 = real part
    mulsd xmm11, xmm11  ; xmm11 = real part ^ 2
    movsd xmm12, xmm8   ; xmm12 = image part
    mulsd xmm12, xmm12  ; xmm12 = image part ^ 2
    subsd xmm11, xmm12  ; xmm11 = (real part ^ 2 - image part ^2)
    addsd xmm11, xmm0   ; xmm11 += cReal

    ; Save for next iteration
    movsd xmm6, xmm11   ; xmm6 = new real part
    movsd xmm8, xmm10   ; xmm8 = new image part

    ; compare |z| with thresholdRadius
    mulsd xmm10, xmm10  ; xmm10 = new image part ^ 2
    mulsd xmm11, xmm11  ; xmm11 = new real part ^ 2
    addsd xmm10, xmm11  ; xmm10 = |z|
    comisd xmm10, xmm3  ; compare |z| with thresholdRadius
    jbe iterate_fractal ; if |z| <= thresholdRadius -> iterate

    inc r11             ; increment iteration

store_byte:
    ; ARGB8888 format
    cmp r13b, 0                 ; compare with colored
    je not_colored
    and r11, 31                 ; iteration % 32
    mov eax, [r12 + r11 * 4]    ; choose color
    mov dword [rcx], eax        ; store color at certain pixel address
    jmp byte_stored

not_colored:
    ; colored = false
    mov byte [rcx], r11b
    mov byte [rcx + 1], r11b
    mov byte [rcx + 2], r11b
    mov byte [rcx + 3], 255

byte_stored:
    add rcx, 4  ; next pixel
    inc r9      ; x += 1
    cmp r9, rdx ; compare x with width
    jl loop_x   ; if x < width -> compute for x

increment_y:
    ; new line
    inc r10     ; incremeent y
    xor r9, r9  ; x = 0
    cmp r10, r8 ; compare y with height
    jl loop_x   ; if y < height -> compute for x

end:
    ; Epilogue
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret
