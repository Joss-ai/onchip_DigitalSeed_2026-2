Lenguaje systemVerilog

Comandos importantes 

sby -f archivo.sby para ejecutarlo

Estructura del archivo sby

[options]
mode bmc
depth 1

[engines]
smtbmc

[script]
read -formal bcd.sv
prep -top bcd_inc

[files]
bcd.sv