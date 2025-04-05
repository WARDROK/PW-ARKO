# RISC-V

A program that draws a square function on a bitmap.
`Y = Ax^2+Bx+C`

Parameters can be set in the `quadratic_function.asm` file in lines 40-43 and 53-54

Parameters:

Lines 40-43\
`scale` - skala rysunku\
`contsA` - współczynnik A\
`contsB` - współczynnik B\
`contsC` - współczynnik C

Lines 53-54\
`ifname` - bitmapa wejściowa\
`ofname` - bitmapa wyjściowa

The quadratic function is drawn on a bitmap with bit depth equal to 1 bit.
We can give the input bitmap with any values. The program will paint the entire background white and then draw the quadratic graph along with the coordinate axes in black.

To run the program, run the `rars_3897cfa` file and then in the upper left corner choose `File -> Open` and select the `quadratic_function.asm` file.
Then select `Run -> Assemble -> F5`. The resulting bitmap will be obtained in the file `result.bmp`.

Several input bitmaps are prepared and can be used.
