# Granular Comments Implementation Example

## For Table Row Comments (Glossary Example)

You could modify the glossary.md to include comment sections for each term:

```markdown
| Begriff | Term | Erklärung | 
|---------|------|-----------|
| **Vermittlung** | **Personnel Placement** | ... |

<div class="row-comments" data-term="vermittlung"></div>

| **Verleih** | **Personnel Lending** | ... |

<div class="row-comments" data-term="verleih"></div>
```

## JavaScript Enhancement

```javascript
// Function to initialize row-specific comments
function initializeRowComments() {
    const rowComments = document.querySelectorAll('.row-comments');
    
    rowComments.forEach(element => {
        const term = element.dataset.term;
        const script = document.createElement('script');
        script.src = 'https://utteranc.es/client.js';
        script.setAttribute('repo', 'your-repo');
        script.setAttribute('issue-term', `glossary-term-${term}`);
        script.setAttribute('theme', 'github-light');
        element.appendChild(script);
    });
}
```

## Alternative: Section Headers

Add comment widgets after each major section:

```markdown
## Hauptgeschäftsmodelle / Core Business Models

[Content here...]

<div class="section-comments" data-section="business-models"></div>

## Akteure / Actors  

[Content here...]

<div class="section-comments" data-section="actors"></div>
```

## Recommendation

For your current needs:
1. **Use "Issue title contains specific term"** 
2. **Start with page-level comments** (current implementation)
3. **Add section-level later** if needed based on user feedback

The current setup provides good specificity without overwhelming complexity.