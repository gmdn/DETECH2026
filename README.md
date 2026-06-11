# DETECH 2026 Evaluation Challenge Repository

This repository contains the datasets prepared for the [**DETECH 2026 Evaluation Challenge**](https://detech2026.dei.unipd.it/), organized into two tasks:

The **DETECH 2026** edition explores the **gut–brain interplay**, a domain at the crossroads of **gastroenterology**, **neuroscience**, and **genetics**. The shared task provides a realistic testbed for evaluating automatic methods that can (i) identify and extract specialized terms and (ii) produce natural language definitions for medical concepts.

## Tasks

### Task A — Term Extraction
Identify relevant **single-word** and **multi-word** terms from English texts concerning the gut–brain interplay.  
The objective is to extract domain-specific terms from the corpus, capturing both repeated mentions in the documents and the list of distinct terms overall (where a mention is an in-text occurrence of a term in a specific document).
Systems may rely on linguistic processing, statistical methods, or neural models, and may optionally use external terminology resources. 

### Task B — Definition Generation
Produce **natural language definitions** for the **concepts designated by the extracted terms**, using corpus-based evidence and/or automatic text generation methods.  
The goal is to generate terminological definitions in the form of intensional definitions, following the guidelines provided in ISO 1087 (2019) and ISO 704 (2022) for concepts relevant within the gut–brain interplay domain.
Approaches can include retrieval-based definition induction, prompting large language models with evidence snippets, or hybrid pipelines that ground generation in the training corpus.

## Participation

We welcome participation from **academic**, **research**, and **industry** teams working in **NLP**, **terminology**, **lexicography**, or **biomedical informatics**.

In particular:

- Up to **five runs per subtask per team** are allowed.
- **External resources** (e.g., pre-trained models, lexicons, ontologies) are permitted but must be **clearly documented**.
- **Manual runs** are accepted but will **not be ranked**.
- Registration details will be available (soon) on this website.

## Evaluation

Each run will be evaluated according to the following measures:

- **Task A — Term Extraction**
  - **Micro-F1**: measures how consistently a system detects **every instance** of a term across the corpus.
  - **Type-F1**: evaluates precision and recall across **unique term types**, disregarding frequency.

- **Task B — Definition Generation**
  - **BLEU score**
  - **BERTScore**
  - Additional **manual/qualitative checks** to assess the **informativeness** and **linguistic quality** of generated definitions.


## Dataset

- **Task A — Automatic Term Extraction (ATE)**
- **Task B — Definition Generation**

Both tasks are provided for two domains:
- **parkinson**
- **mental_health**

Each task uses **document-level identifiers** (`num_article`) that correspond to abstract filenames.

### Annotation protocol and data preparation

In the annotation protocol document, **[DETECH 2026 Evaluation Task Annotation Protocol](Annotation_Protocol/DETECH_Annotation_Protocol-final-2201.pdf)**, we describe the annotation protocol adopted to create the DETECH dataset. 

---

## Task A — Automatic Term Extraction (ATE)

Task A focuses on identifying relevant term mentions from biomedical abstracts.

### Folder structure

```text
task_ATE/
  training/
    abstracts/
      parkinson/        (pa_<id>.txt)
      mental_health/    (mh_<id>.txt)
    taskA_parkinson_train.csv
    taskA_mental_health_train.csv
    taskA_parkinson_terms_train.csv
    taskA_mental_health_terms_train.csv

  test/   (may be present as a placeholder in the package)
```

## What Task A contains

Task A provides:
1. **Abstracts** (one plain-text file per document)
2. **Document lists** (training/test membership)
3. **Term annotations** (highlighted/extracted terms; one row per term occurrence)

### Abstract files (`abstracts/`)
- One `.txt` file per document.
- Naming convention: `pa_<id>.txt` (Parkinson) and `mh_<id>.txt` (Mental health).
- `<id>` corresponds to `num_article` used in Task A CSV files.
- Each file typically contains a header line, a blank line, and the abstract text.

### CSV schemas (Task A)

#### A.1 Document lists (`taskA_*_train.csv`)
Columns:
- `num_article` — document identifier matching filename id
- `doi` — DOI string (may be empty)

#### A.2 Term files (`taskA_*_terms_train.csv`)
Columns:
- `num_article` — document identifier
- `doi` — DOI associated with the document (may be empty)
- `term` — extracted/highlighted term string

---


## Task B — Definition Generation

Task B focuses on identifying relevant concepts and define them

### Folder structure

```text
task_Definition/
  training/
    abstracts/
      parkinson/        (pa_<id>.txt)
      mental_health/    (mh_<id>.txt)
    taskB_parkinson_train.csv
    taskB_mental_health_train.csv
    taskB_Mentions_parkinson_train.csv
    taskB_Mentions_mental_health_train.csv
    taskB_Definitions_train.csv

  test/   (may be present as a placeholder in the package)
```

## What Task B contains

Task B provides:
1. **A training subset of abstracts**
2. **Task B document lists** per domain
3. **Mentions supervision** linking *mention -> concept*
4. **Gold intensional definitions** for concepts

### Abstract files (`training/abstracts/`)
- One `.txt` file per document.
- Naming convention: `pa_<id>.txt` (Parkinson) and `mh_<id>.txt` (Mental health).
- `<id>` corresponds to `num_article` used in Task B CSV files.
- These abstracts are a subset of the Task A training set selected for Task B training.

### CSV schemas (Task B)

#### B.1 Document lists (`taskB_parkinson_train.csv`, `taskB_mental_health_train.csv`)
Columns:
- `num_article` — document identifier matching filename id
- `doi` — raw DOI or DOI URL such as `https://doi.org/...`

#### B.2 Mentions supervision (`taskB_Mentions_*_train.csv`)
Columns:
- `num_article` — document identifier
- `doi` — DOI associated with the document
- `mention` — surface form in the abstract
- `concept` — normalized concept label assigned to the mention

#### B.3 Gold definitions (`taskB_Definitions_train.csv`)
Columns:
- `<Concept>` — concept label
- `Intensional definition` — intensional definition text



# What participants should submit

### Task A — Automatic Term Extraction (ATE)

For **each run**, participants must submit **two CSV files**, one per domain:

- `taskA_parkinson_terms.csv`
- `taskA_mental_health_terms.csv`

#### File format (both domains)
Each CSV must contain the following columns (header not required):

| column        | description |
|--------------|-------------|
| `num_article` | document identifier  |
| `doi`         | DOI of the document (may be empty if unavailable) |
| `term`        | extracted term string |

Each row corresponds to one extracted term occurrence for a given document.

---

### Task B — Definition Generation

For each run, participants must submit **two CSV files per domain** (total: 4 files):

#### 1) Concept assignment file (mentions → concepts)
- `taskB_parkinson_concepts.csv`
- `taskB_mental_health_concepts.csv`

Columns (header not required):

| column        | description |
|--------------|-------------|
| `num_article` | document identifier  |
| `doi`         | DOI of the document (may be empty if unavailable) |
| `mention`     | mention string found in the document |
| `concept`     | concept label assigned to the mention |

Each row links a mention in a document to the predicted concept.

#### 2) Definition file (concept -> definition)
- `taskB_parkinson_definitions.csv`
- `taskB_mental_health_definitions.csv`

Columns (header not required):

| column      | description |
|------------|-------------|
| `concept`    | concept label |
| `definition` | generated intensional definition for the concept |

Each row contains one generated definition for a concept.


## Participant Runs

The `runs/` folder contains the submissions provided by participating teams.

```text
runs/
├── TeamA/
├── TeamB/
├── TeamC/
└── ...
```

Each team has a dedicated folder containing the runs submitted for Task A and Task B.

### Folder structure

```text
runs/
└── team_name/
    ├── taskA/
    └── taskB/
```

The evaluation scripts automatically scan the team folders and load all available runs.

### Task A submissions

Task A runs are stored as CSV files inside:

```text
runs/team_name/taskA/
```

Each file corresponds to one submitted run and contains extracted term occurrences.

Expected columns:

| column        | description                        |
| ------------- | ---------------------------------- |
| `num_article` | document identifier                |
| `doi`         | DOI of the document (may be empty) |
| `term`        | extracted term                     |

Example:

```text
num_article,doi,term
2,10.1016/j.nut.2024.112369,Gut microbiota
2,10.1016/j.nut.2024.112369,Malnutrition
```

The evaluation scripts support both comma-separated (`.csv`) and semicolon-separated (`.csv`) files. Headers are optional.

### Task B submissions

Task B runs are stored inside:

```text
runs/team_name/taskB/
```

Each Task B run consists of two files:

1. a concept identification file;
2. a definition generation file.

The filename contains the subcollection name (`mental_health` or `parkinson`) and uniquely identifies the run.

#### Concept identification file

Expected columns:

| column        | description                        |
| ------------- | ---------------------------------- |
| `num_article` | document identifier                |
| `doi`         | DOI of the document (may be empty) |
| `mention`     | mention occurring in the document  |
| `concept`     | predicted concept                  |

Example:

```text
num_article,doi,mention,concept
1,10.1016/j.psychres.2024.115914,antipsychotics,<Antipsychotic>
1,10.1016/j.psychres.2024.115914,gastrointestinal microbiota,<Gastrointestinal microbiota>
```

#### Definition generation file

Expected columns:

| column       | description                      |
| ------------ | -------------------------------- |
| `concept`    | concept label                    |
| `definition` | generated intensional definition |

Example:

```text
concept,definition
<Antipsychotic>,drug used to treat psychotic disorders
<Gastrointestinal microbiota>,community of microorganisms inhabiting the gastrointestinal tract
```

### Multiple runs

The evaluation pipeline automatically:

* detects all available runs;
* associates each run with its team and subcollection;
* computes all evaluation measures;
* generates per-team feedback files.

Run identifiers are derived from the filenames and are preserved throughout the evaluation process, allowing participants to compare alternative system configurations.


## Evaluation

The `evaluation/` folder contains all scripts required to reproduce the official DETECH 2026 evaluation.

```text
evaluation/
├── task_ATE/
└── task_Definition/
```

Each subfolder contains:

* scripts for loading gold standards and participant submissions;
* scripts implementing the official evaluation measures;
* scripts for exporting participant feedback files;
* generated evaluation outputs.

### Task A — Automatic Term Extraction

The `task_ATE/` folder contains the evaluation pipeline for Task A.

```text
evaluation/task_ATE/
├── load_data.R
├── measures.R
├── evaluate.R
├── export_results_with_median.R
├── run_all.R
└── team-feedback/
```

The evaluation computes:

* Micro Precision
* Micro Recall
* Micro F1
* Type Precision
* Type Recall
* Type F1

Term matching is performed after normalization (case-insensitive comparison and whitespace normalization), while singular/plural variants are treated as distinct terms.

The generated feedback files include, for each submitted run:

* all evaluation measures;
* first quartile (Q1);
* median;
* third quartile (Q3).

### Task B — Concept Identification and Definition Generation

The `task_Definition/` folder contains the evaluation pipeline for Task B.

```text
evaluation/task_Definition/
├── load_data.R
├── evaluate_concept_recall.R
├── compute_bleu.R
├── compute_rouge.R
├── compute_bertscore.R
├── create_virtualenv.R
├── run_all.R
├── models/
└── team-feedback/
```

Task B evaluation consists of two components.

#### Concept Identification

Concepts are matched using:

* `num_article`
* normalized concept label

Concept normalization removes:

* angle brackets (`< >`);
* case differences;
* leading/trailing whitespace.

The primary measure is:

* Concept Recall

#### Definition Generation

Definitions are evaluated only for concepts that are correctly identified in the corresponding document.

The following automatic measures are computed:

| Measure   | Description                                              |
| --------- | -------------------------------------------------------- |
| BLEU-1    | Unigram overlap                                          |
| BLEU-2    | Bigram overlap                                           |
| BLEU-3    | Trigram overlap                                          |
| ROUGE-1   | Unigram overlap recall                                   |
| ROUGE-2   | Bigram overlap recall                                    |
| ROUGE-L   | Longest common subsequence overlap                       |
| BERTScore | Semantic similarity using a biomedical transformer model |

BLEU is computed using the Python package `sacrebleu`, ROUGE using `rouge-score`, and BERTScore using `bert-score` through the `reticulate` package.

The generated feedback files include:

* concept recall;
* BLEU scores;
* ROUGE scores;
* BERTScore scores;
* number of evaluated concept-definition pairs (`n_pairs`);
* first quartile (Q1);
* median;
* third quartile (Q3).

### Reproducibility

All official DETECH 2026 evaluation results can be reproduced by running:

```r
source("run_all.R")
```

inside the corresponding evaluation folder.

Task B additionally requires a Python environment configured through `reticulate`. The required environment can be created using:

```r
source("create_virtualenv.R")
```


> [!IMPORTANT]
> Due to GitHub's file size limitations, the file `model.safetensors` used by the local PubMedBERT model is not included in this repository.
>
> To restore the complete model, download it from the original Hugging Face repository:
>
> https://huggingface.co/microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext
>
> and place the downloaded `model.safetensors` file in:
>
> ```text
> evaluation/task_Definition/models/pubmedbert-fixed/
> ```
>
> After downloading, the folder should contain files such as:
>
> ```text
> pubmedbert-fixed/
> ├── config.json
> ├── model.safetensors
> ├── special_tokens_map.json
> ├── tokenizer_config.json
> ├── tokenizer.json
> └── vocab.txt
> ```
>
> Alternatively, the model can be recreated automatically by running:
>
> ```r
> source("create_virtualenv.R")
> ```
>
> and following the instructions in `compute_bertscore.R`.
