# know-rec
Knowledge-based experiments with TaoMiner/joint-kg-recommender and sunzhuntu/Recurrent-Knowledge-Graph-Embedding projects.

## Setup

$ setup.sh

Download Cao datasets from https://drive.google.com/file/d/1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW/view
Move Cao's ml1m data to ml1m-cao.

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
| | | Cao's data
| └─ml1m-sun
| | | Sun's data
| └─ml1m-sun2cao
| └─ml1m-cao2sun
└─joint-kg-recommender
└─Recurrent-Knowledge-Graph-Embedding
└─results
| └─ml1m-cao
| └─ml1m-sun
