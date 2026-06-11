library(reticulate)

reticulate::virtualenv_create("detech")

reticulate::py_require(c(
  "sacrebleu",
  "rouge-score",
  "bert-score",
  "torch",
  "transformers",
  "tokenizers",
  "sentencepiece",
  "tiktoken"
))
