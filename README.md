# know-rec
Knowledge-based experiments with TaoMiner/joint-kg-recommender and sunzhuntu/Recurrent-Knowledge-Graph-Embedding projects.

## Setup

This code was deployed on a machine with an Intel(R) Xeon(R) CPU E5-2640 v4 @ 2.40GHz, 10 physical cores (HT enabled), L1 cache: 32KB data, 32KB instruction per core, L2 cache: 256KB per core,  L3 cache: 25MB accessible by all CPU core, NUMA nodes: 2 (20 physical cores + HT), 128 GB of RAM, NVIDIA Tesla K40c, running the linux Ubuntu 16.06 x86_64.

Use the following steps in order to setup our project properly.

1. Run setup script.<br />
`$ setup.sh`
2. Download Cao datasets from https://drive.google.com/file/d/1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW/view<br />
3. Move Cao's ml1m data to ~/git/datasets/ml1m-cao.<br />
4. Create symbolic links between Cao's ml1m data and ~/git/datasets/ml1m-sun2cao.<br />
`$ ln -s ~/git/datasets/ml1m-cao/ml1m/\*.dat ~/git/datasets/ml1m-sun2cao/`

Git folder should have the follow structure:

```
git
└─know-rec
| └─preprocess
| | | cao2sun_step1.py
| | | sun2cao_step1.py
| | | sun2cao_step2.p
| README.md
└─datasets
| └─ml1m-cao
| | └─ml1m
| | | | Cao's data
| └─ml1m-sun
| | └─ml1m
| | | | Sun's data
| └─ml1m-sun2cao
| | └─ml1m
| | | | Cao's data without kg (only *.dat)
| └─ml1m-cao2sun
| | └─ml1m
└─joint-kg-recommender
└─orbs
└─Recurrent-Knowledge-Graph-Embedding
└─results
| └─ml1m-cao
| └─ml1m-sun
```

5. Install cuda 7.5 from https://developer.nvidia.com/cuda-75-downloads-archive<br />
6. Create python environment for each project.<br />
`$ bash -i util/create_envs.sh`

## Run

`$ bash -i preprocess/preprocess_crossvalid.sh`

`$ bash -i run/run_ml1m-crossvalid.sh`
