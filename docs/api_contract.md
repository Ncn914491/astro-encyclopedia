# API Contract

## Object Response Structure

The Worker MUST return the following JSON structure for any object (Galaxy, Star, or APOD):

```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "imageUrl": "string (proxied URL)",
  "type": "galaxy|star|planet|nebula",
  "metadata": { "distance": "string", "constellation": "string" },
  "source": "NASA"
}
```

**The Mobile App never speaks to NASA. It only speaks to this Schema.**
