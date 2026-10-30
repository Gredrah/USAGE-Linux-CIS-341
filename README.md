# USAGE-Linux-CIS-341
USAGE application project for Linux and CIS 341 (System Administration)

USAGE-daemon/
├── config
│   ├── USAGE.conf                     # Default configuration file
│   └── USAGE.conf.example             # Fully documented template
├── cron/                              # Automated cron jobs related to the system
├── deploy/                            # The "installation" folder that contains set up scripts.
│   └── install.sh                     # Automated deploy script creating dirs & users, "run once" philosophy
|                                      # Potentially more files relating to user set up due to our modular assignment of responsibility
├── docs/                              # "Presentation"/Docs
│   ├── ARCHITECTURE.?                 # Component diagrams, data flow, pipeline maps
│   ├── BOTTLENECKS.?                  # Performance profiling & optimization analysis
│   ├── PRESENTATION.?                 # Final presentation slide deck
│   └── screenshots/                   # Verification proofs, test runs, CLI traces
├── src/                               # USAGE engine main.sh and other files
├── systemd/                           # Systemd.service and .timer files if we do not use cron to run the automated jobs
├── tests/                             # Testing suites within
├── .gitignore                         # Add any undesired files here, they will be excluded from upload
├── Makefile                           # If necessary / desired
└── README.md                          # Quickstart, project overview
