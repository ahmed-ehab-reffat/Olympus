---
Repository: https://github.com/open2b/scriggo
Issue: N/A
Commit: 2f437fb8222e48af03cf4087794b05a23316b07a
Language: Go
Category: feature-request
Title: Add CSS and JavaScript escaping contexts inside HTML attribute values
---
# Add CSS and JavaScript escaping contexts inside HTML attribute values

Add CSS and JavaScript contexts to the template autoescaper for values shown inside HTML attribute values. Today a show inside `<style>` is escaped as CSS and one inside `<script>` as JavaScript, but inside `style="..."` or `onclick="..."` the value only gets attribute escaping, so `onclick="f('{{ v }}')"` lets a quote in `v` break out of the string.

The value of a `style` attribute is CSS, and the value of any attribute whose name is `on` followed by at least one more character is JavaScript. Attribute names match case-insensitively. Every other attribute keeps its current behavior.

A value shown there is first escaped exactly as it would be at the same point inside a `<style>` or `<script>` element, and the result is then escaped as for an ordinary attribute value, quoted or unquoted as the attribute is. So strings are written as quoted CSS or JavaScript strings, `native.CSS` and `native.JS` values (and their stringer interfaces) skip only the first step, and a type that cannot be shown in the element cannot be shown in the attribute either, so building the template fails.

Inside the value, a quote opens a CSS or JavaScript string just as it does inside the element, and the matching quote closes it, so a show between them is escaped for the inside of a string. A quote written as a character reference counts as that quote: `&quot;`, `&apos;`, or a decimal or hexadecimal numeric reference such as `&#39;` or `&#x22;`. A backslash before the quote keeps the string open, JavaScript comments are skipped as in `<script>`, and the attribute's own delimiter always ends the attribute.

This applies to HTML and Markdown templates.
