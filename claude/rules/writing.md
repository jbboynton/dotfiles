# Writing rules

James's writing defaults for every project and every kind of prose: docs, agent output, chat replies, customer copy, email, and commits. A project may override a rule in writing when it has a good reason. Project brand voice (such as NFF's) lives in that project and layers on top.

## Punctuation

- No semicolons.
- No em dashes in any prose, however short. The one exception is the NFF sign-off "— James and Jim".
- Oxford comma: "eggs, chicken, and pork".
- No comma splices. Two complete clauses take a period.
- A fragment used as a label, badge, row heading, or row value takes no end punctuation. Full sentences keep theirs.

## Structure and argument

- Have a thesis: start with a topic sentence, then support it with details.
- Lead with the substance. No preamble selling.
- Don't repeat yourself. Assume the reader is intelligent, draws inference, and needs no hand-holding. Write confidently and directly.
- Hedge only when unsure, and say it once. Avoid superlatives and broad brushes. Acknowledge gray areas, trade-offs, pros and cons.
- No unbacked claims and no numbers nobody measures.
- Give step-by-step instructions only for what the reader may not know.
- No cruft in anything authored, including docs, READMEs, and plans.
- No caveats up front. Give the point first, and put a needed caveat after it.
- Terse documents. A doc holds what the reader needs and stops.

## Sentence construction

- No sentence fragments in prose. Button labels, tooltips, and badges may be fragments.
- No fragment after a fragment, and no riddles.
- Constructions to avoid (this list grows over time):
  - Reversal pivots: "It's not X, it's Y", "This isn't about X. It's about Y.", "Not X but Y", and "The real story is Y" used only as a pivot.
- No symmetry padding. No sentence balanced for its own sake, and no three-part list unless all three earn their place.
- Vary sentence length and construction. Don't follow one sentence with another of the same length and construction, and flag 4 similar-length sentences in a row.
- Active voice by default.
- Positive form: "dishonest", not "not honest".
- No dangling modifiers. An opening phrase refers to the sentence's subject.
- Parallel ideas in parallel form.
- Keep related words together, and put the emphatic word at the end.

## Word choice

- Choose each word with care. Say as little as necessary, use simple language by default, and select precisely the word you need. Terse and easy to follow. Draw on a vast vocabulary to say exactly what you mean in as few words as you can. Plain English, concrete over abstract, no jargon.
- Omit needless words: "the fact that", "the question as to whether", "in a hasty manner", "this is a subject which".
- No filler transitions or openers: "at its core", "that said", "ultimately", "in today's world", "it's important to note", "in a world where", "let's explore", "what this means is", "on the one hand".
- No marketing buzzwords: "seamless", "intuitive", "powerful", "robust", "next-gen", "clean", "modern", "polished". Show it, don't claim it.
- No repeated words across the whole piece of writing, not just within a sentence. Not literal: it applies mostly to nouns, adjectives, verbs, and adverbs, not to words like "the" and "and". Stock phrases such as "of course" appear once per piece at most.
- One term for one thing, everywhere.
- An approved wording applies everywhere the same text appears.
- Vary phrases that repeat across pages and posts, keeping the facts true.
- No internal or model names in reader-facing text.
- Get the domain nouns right.
- "Email address" when you mean the address, not "email".
- American English. Rewrite British spelling and idioms to an American equivalent.

## Tone

- Clear, clean writing: plain words, one idea per sentence, and cut what doesn't earn its place.
- No jokes in transactional text, such as errors, payment, and deletion.

## Interface copy

- Buttons start with a verb and name the outcome: "Create account", not "Submit". A confirm dialog's buttons name the action: "Delete files" and "Keep files", not "OK" and "Cancel".
- Error messages say what happened, why, and how to fix it.
- Empty states explain only when an explanation is needed. No statements of fact unless needed.
- Confirm dialogs name the action and its consequence: "Delete 3 files?" and "This can't be undone", not "Are you sure?".

## Formatting and naming

- Commit messages: header in the imperative, sentence case, no trailing period, 50 characters at most, never an issue or PR number. Then a blank line, a one-sentence summary, another blank line, and the rest of the body. The body is Markdown, wrapped at 72 characters, and only URLs may run longer.
- Images in Markdown (commits included) go in a one-column table:

  ```
  | [IMAGE] |
  |:---:|
  | [CAPTION] |
  ```

- In chat, refer to GitHub issues and PRs as `[#number, title](link)`. Docs and commits are not chat.
- Questions for James are yes or no, or lettered choices.
- No Markdown in spoken (voice mode) replies.
- File names: a spaced en dash ( – ) as separator. No "Copy of", appended numbers, or "Final" without reason. A major version like "v2" after its own separator.
- ISO dates (YYYY-MM-DD) in working documents. Customer copy spells dates out.
- Keep a paragraph's last two words together, and never split a time from its AM or PM.
- Calendar titles short and terse, no person names, and plain Unicode symbols over emoji.
- Bullets for lists. Items that share a pattern go in a bulleted or numbered list, not a run of sentences.
