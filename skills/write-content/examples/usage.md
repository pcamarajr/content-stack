# write-content Usage Examples

## Single article (interactive)

```text
/write-content article "Getting Started with Docker"
```

→ Type: article, Source: user prompt, Mode: interactive
→ Asks 3-5 interview questions, then writes a full article with research, glossary, linking

## Single article (topic only — asks for type)

```text
/write-content "Getting Started with Docker"
```

→ Type: asks user (article or glossary?), Source: user prompt, Mode: interactive

## Glossary entries (interactive)

```text
/write-content glossary "container, image, volume"
```

→ Type: glossary, Source: user prompt, Mode: interactive
→ Creates multiple glossary entries in one run

## Single glossary entry

```text
/write-content glossary "load balancer"
```

→ Type: glossary, Source: user prompt, Mode: interactive

## Backlog — first N articles (autonomous)

```text
/write-content backlog 3
```

→ Writes the first 3 pending backlog articles sequentially, auto-committing each

## Backlog — specific items (autonomous)

```text
/write-content backlog #1,#3,#5
```

→ Writes specific backlog items by number

## Backlog — all pending (autonomous)

```text
/write-content backlog all
```

→ Writes all pending backlog articles

## No arguments (fully interactive)

```text
/write-content
```

→ Asks the user what to create (article or glossary) and the topic
