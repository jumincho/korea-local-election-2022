# Relative links in the READMEs must point to files that exist, and anchors to
# headings that exist (using GitHub's rules for heading anchors).

read_doc <- function(path) readLines(path, encoding = "UTF-8", warn = FALSE)

heading_anchors <- function(lines) {
  headings <- sub("^#+\\s+", "", grep("^#{1,6}\\s", lines, value = TRUE))
  headings <- gsub("`", "", headings)
  gsub(" ", "-", gsub("[^a-z0-9 _-]", "", tolower(headings)))
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

docs <- c("README.md", file.path("data", "README.md"), file.path("data-raw", "README.md"))

test_that("relative links and anchors in the READMEs resolve", {
  for (doc in docs) {
    expect_gt(length(relative_links(read_doc(here::here(doc)))), 3)
    expect_identical(broken_links(doc), character(), info = doc)
  }
})

test_that("the link checker notices broken links", {
  doc <- tempfile(fileext = ".md")
  writeLines(c("# Title", "[ok](#title) [bad](#nope) [gone](missing.csv)"), doc)
  lines <- read_doc(doc)
  ok <- vapply(relative_links(lines), link_resolves, logical(1), doc_path = doc, doc_lines = lines)
  expect_identical(unname(ok), c(TRUE, FALSE, FALSE))
})
