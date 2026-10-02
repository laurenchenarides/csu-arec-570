```{=html}
<table class="table table-hover">
  <thead>
    <tr>
      <th>Lecture</th>
      <th>Focus</th>
      <th>Student PDF</th>
    </tr>
  </thead>
  <tbody class="list">
  <% for (const item of items) { %>
    <tr <%= metadataAttrs(item) %>>
      <td>
        <a href="<%- item.path %>" class="listing-title" target="_blank" rel="noopener"><%= item.title %></a>
      </td>
      <td>
        <span class="listing-description"><%= item.description || '' %></span>
      </td>
      <td>
      <% if (item.pdf) { %>
        <a href="<%- item.pdf %>" class="listing-pdf text-nowrap" target="_blank" rel="noopener">Download PDF</a>
      <% } else { %>
        <span aria-label="No PDF available">—</span>
      <% } %>
      </td>
    </tr>
  <% } %>
  </tbody>
</table>
```
