# Creating MotherDuck Dives

[Dives](https://motherduck.com/docs/key-tasks/ai-and-motherduck/dives/) are interactive visualizations that live in your MotherDuck workspace. They query live data and stay up to date.

## Setup

The **remote** MotherDuck MCP server is configured in `.cursor/mcp.json`:

```json
"MotherDuck": {
  "url": "https://api.motherduck.com/mcp",
  "type": "http"
}
```

1. **Restart Cursor** (or reload the window) so it picks up the new MCP server.
2. Open **Settings → Tools & MCP** and **Connect** the MotherDuck server. You’ll be asked to sign in with your MotherDuck account (OAuth).
3. The remote server exposes Dive tools (`save_dive`, `get_dive_guide`, `update_dive`, `list_dives`, etc.) in addition to query and schema tools.

You can keep using the local `mcp-server-motherduck` for read-only queries against `md:imdb_analytics`; use the remote **MotherDuck** server when you want to create or edit Dives.

## Create the “Top 10 Netflix directors” Dive

After the MotherDuck MCP is connected, ask in chat (in a conversation where the MotherDuck MCP is available):

**Prompt:**

> Create a Dive showing the **top 10 best IMDB-rated titles** from directors who have at least one title on Netflix. Use a card or table layout with title, director, year, genre, IMDB rating, vote count, and overview. Data comes from `imdb_analytics.raw.raw_imdb` (series_title, released_year, genre, imdb_rating, overview, director, no_of_votes) and `imdb_analytics.raw.raw_netflix` (director). Join on director; order by imdb_rating DESC, then no_of_votes DESC; limit 10. Title the Dive “Top 10 IMDB · Netflix directors”.

The AI will call `get_dive_guide` for the correct React/JSX format, then `save_dive` to persist the Dive in your MotherDuck workspace. You’ll get a link to open it in the [MotherDuck app](https://app.motherduck.com).

## More Dive ideas (same database)

- *“Create a Dive with a bar chart of top 10 directors by average IMDB rating (only directors with at least 3 titles).”*
- *“Create a Dive showing IMDB rating distribution by genre for titles from Netflix directors.”*
- *“Create a Dive with a line chart of number of Netflix titles added per year.”*

## References

- [Creating visualizations with Dives](https://motherduck.com/docs/key-tasks/ai-and-motherduck/dives/)
- [MotherDuck MCP (remote vs local)](https://motherduck.com/docs/sql-reference/mcp/)
- [save_dive](https://motherduck.com/docs/sql-reference/mcp/save-dive/) · [get_dive_guide](https://motherduck.com/docs/sql-reference/mcp/get-dive-guide/)
