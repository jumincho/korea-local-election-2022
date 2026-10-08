# Relative links in the READMEs and their translations must point to files that
# exist, and anchors to headings that exist (using GitHub's rules for heading
# anchors). Every README opens with the same language switcher.

read_doc <- function(path) readLines(path, encoding = "UTF-8", warn = FALSE)

# GitHub's anchor for each heading: the text without backticks, lowercased, with
# every character that is not a letter, digit, mark, space, hyphen or underscore
# removed (so Hangul, kana and CJK ideographs stay, and punctuation such as
# "." or "・" goes), then spaces turned into hyphens. Lines inside fenced code
# blocks are not headings.
heading_anchors <- function(lines) {
  in_code <- cumsum(grepl("^\\s*(```|~~~)", lines)) %% 2 == 1
  headings <- sub("^#+\\s+", "", grep("^#{1,6}\\s", lines[!in_code], value = TRUE))
  headings <- gsub("`", "", headings)
  gsub(" ", "-", gsub("[^\\p{L}\\p{N}\\p{M} _-]", "", tolower(headings), perl = TRUE))
}

relative_links <- function(lines) {
  text <- paste(lines, collapse = "\n")
  markdown <- regmatches(text, gregexpr("\\]\\([^)[:space:]]+\\)", text))[[1]]
  html <- regmatches(text, gregexpr("(src|href)=\"[^\"]+\"", text))[[1]]
  links <- c(gsub("^\\]\\(|\\)$", "", markdown), gsub("^(src|href)=\"|\"$", "", html))
  links[!grepl("^(https?|mailto):", links)]
}

link_resolves <- function(link, doc_path, doc_lines) {
  target <- sub("#.*$", "", link)
  anchor <- if (grepl("#", link)) sub("^[^#]*#", "", link) else ""
  target_path <- file.path(dirname(doc_path), target)
  if (nzchar(target) && !file.exists(target_path)) {
    return(FALSE)
  }
  if (!nzchar(anchor) || (nzchar(target) && !grepl("[.]md$", target))) {
    return(TRUE)
  }
  anchor %in% heading_anchors(if (nzchar(target)) read_doc(target_path) else doc_lines)
}

broken_links <- function(doc) {
  path <- here::here(doc)
  lines <- read_doc(path)
  links <- relative_links(lines)
  links[!vapply(links, link_resolves, logical(1), doc_path = path, doc_lines = lines)]
}

# The READMEs in the order of the language switcher.
readmes <- c("README.md", "README.ko.md", "README.zh-CN.md", "README.zh-HK.md", "README.ja.md")
docs <- c(readmes, file.path("data", "README.md"), file.path("data-raw", "README.md"))

# The items of a language switcher line such as
# "<flag> **English** | <flag> [한국어](README.ko.md) | ...": the flag, the
# language name, whether it is the bold (current) one, and the link target.
# Items that do not have either form get NA throughout.
switcher_items <- function(line) {
  items <- strsplit(line, " | ", fixed = TRUE)[[1]]
  pattern <- "^(\\S+) (?:\\*\\*([^*]+)\\*\\*|\\[([^]]+)\\]\\(([^)]+)\\))$"
  parts <- regmatches(items, regexec(pattern, items, perl = TRUE))
  part <- function(i) vapply(parts, function(p) p[i], character(1))
  bold <- nzchar(part(3), keepNA = TRUE)
  data.frame(
    flag = part(2),
    name = ifelse(bold, part(3), part(4)),
    bold = bold,
    target = part(5)
  )
}

test_that("relative links and anchors in the READMEs resolve", {
  for (doc in docs) {
    expect_gt(length(relative_links(read_doc(here::here(doc)))), 3)
    expect_identical(broken_links(doc), character(), info = doc)
  }
})

test_that("every README opens with the switcher: fixed order, own language in bold", {
  switchers <- lapply(readmes, function(doc) switcher_items(read_doc(here::here(doc))[1]))
  labels <- paste(switchers[[1]]$flag, switchers[[1]]$name)
  expect_identical(switchers[[1]]$name[1], "English")
  for (i in seq_along(readmes)) {
    s <- switchers[[i]]
    expect_identical(nrow(s), length(readmes), info = readmes[i])
    expect_false(anyNA(s$name), info = readmes[i])
    expect_identical(paste(s$flag, s$name), labels, info = readmes[i])
    expect_identical(which(s$bold), i, info = readmes[i])
    expect_identical(s$target, replace(readmes, i, ""), info = readmes[i])
    expect_true(all(file.exists(here::here(s$target[-i]))), info = readmes[i])
  }
})

test_that("switcher_items parses links and bold names, and flags anything else", {
  s <- switcher_items("A **One** | B [Two](two.md) | C three")
  expect_identical(s$name, c("One", "Two", NA))
  expect_identical(s$bold, c(TRUE, FALSE, NA))
  expect_identical(s$target, c("", "two.md", NA))
})

test_that("the link checker notices broken links", {
  doc <- tempfile(fileext = ".md")
  writeLines(c("# Title", "[ok](#title) [bad](#nope) [gone](missing.csv)"), doc)
  lines <- read_doc(doc)
  ok <- vapply(relative_links(lines), link_resolves, logical(1), doc_path = doc, doc_lines = lines)
  expect_identical(unname(ok), c(TRUE, FALSE, FALSE))
})

test_that("anchors of Hangul, CJK and kana headings follow GitHub's rules", {
  lines <- c(
    "# Title", "### 1. 시도별 당선 정당", "### 2. 2022 年的得票差距（图）",
    "### 6. 性別・年齢層別の出口調査", "```sh", "# Not a heading", "```"
  )
  expect_identical(
    heading_anchors(lines),
    c("title", "1-시도별-당선-정당", "2-2022-年的得票差距图", "6-性別年齢層別の出口調査")
  )
  # "#1---" is what stripping everything outside a-z0-9 would make of heading 1.
  links <- c("#1-시도별-당선-정당", "#2-2022-年的得票差距图", "#1---", "#not-a-heading")
  ok <- vapply(links, link_resolves, logical(1), doc_path = "README.md", doc_lines = lines)
  expect_identical(unname(ok), c(TRUE, TRUE, FALSE, FALSE))
})
