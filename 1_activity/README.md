# RTL2GDS using Open Source EDA Tools

Esta es la actividad  introductoria de semillero, con ella se busca presentar las herramientas OSCI (Open Source Integrated Circuits tools) utilizando un entorno Linux. 

Su desarrollo consistió en la descripción RTL de un encoder de 8 a 3 bits, su simulación desde la consola y la realización de su dieño fisico utilizndo el flujo Librelane.

## Estructura

```text
1_activity/
├── README.md
├── RTL/
│   └── Encoder.v
│   └── Encoder_TB.v
│   └── Waveforms.vcd
│   └── a.out
└── GDS/
    └── config.json
    └── runs/
        └── RUN_2026-08-28_16-13-43/
    
```

* `RTL/` — Contiene los archivos fuente del encoder así con los resultados de su simulación en consola y en GTK wave.
* `GDS/` — Contiene el archivo de configuración así como el resultado de síntesis.
