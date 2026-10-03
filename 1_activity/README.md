# RTL2GDS using Open Source EDA Tools

This activity is part of DigitalSeed, a training initiative developed within the OnChip research group. The activity focuses on introducing the RTL-to-GDSII (RTL2GDS) design flow using open-source EDA tools in a Linux environment.

The objective is to start from the RTL description of the design and configure the required parameters to obtain the corresponding GDSII layout.
## Directory Structure

```text
1_activity/
├── README.md
├── RTL/
│   └── encoder.v
└── GDS/
    └── encoder.json
```

* `RTL/` — Contains the source code of the **encoder** design, which serves as the starting point of the RTL2GDS flow.
* `GDS/` — Contains the `.json` configuration file used to define the parameters required for the physical design flow.

The complete flow can be summarized as:

**RTL → Simulation → Synthesis → Physical Design → GDSII**

The files included in this repository contain the necessary source code and configuration used in the tutorial. The remaining files generated during the RTL2GDS flow can be reproduced by executing the corresponding EDA tools and configuration.


