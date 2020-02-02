# know-rec
Knowledge-based experiments with TaoMiner/joint-kg-recommender and sunzhuntu/Recurrent-Knowledge-Graph-Embedding projects.

## Setup

1. Run setup script.
$ setup.sh

2. Download Cao datasets from https://drive.google.com/file/d/1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW/view

3. Move Cao's ml1m data to ml1m-cao.

4. Copy Cao's ml1m data to ml1m-sun2cao.
$ cp ~/git/datasets/ml1m-cao/ml1m/\*.dat ~/git/datasets/ml1m-sun2cao/

Git folder should have the follow structure:

git
└─know-rec
| └─preprocess
| | | cao2sun_step1.py
| | | sun2cao_step1.py
| | | sun2cao_step2.py
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
└─Recurrent-Knowledge-Graph-Embedding
└─results
| └─ml1m-cao
| └─ml1m-sun
