---
name: Request Review on PR
description: Automatically request reviews when PR is ready and tasks are complete
on:
  pull_request:
    types: [opened, edited, synchronize]
  slash_command:
    name: review
    events: [pull_request, pull_request_comment, issue_comment]
    reaction: eyes
permissions:
  pull-requests: read
  contents: read
  checks: read
  issues: read
safe-outputs:
  add-comment:
    max: 1
    target: "triggering"
    hide-older-comments: true
  add-reviewer:
    max: 3
    target: "triggering"
---

# Request Review Workflow

This workflow automatically requests reviews on pull requests when they are ready and tasks are complete.

## Triggers

This workflow runs when:
- A pull request is opened, edited, or synchronized
- A `/review` slash command is posted in PR comments, issue comments, or PR review comments

## Workflow Steps

### 1. Check Trigger Conditions

First, validate that we should proceed:

- If triggered by a comment, verify it contains the `/review` command
- If triggered by PR event, check the rate limit (no more than once every 2 hours since last review request)
- Verify that all required checks are passing on the PR

### 2. Get PR and Issue Details

Fetch the following information:
- Current pull request number, title, and description
- Associated issue (if any) from the PR description
- All commits in the PR
- Status of all check runs and status checks
- Previous review requests and their timestamps
- Previous comments to find the last reviewed commit SHA

### 3. Check Task Completion

If there is a task checklist in the PR description or associated issue:
- Parse all tasks (look for `- [ ]` for incomplete and `- [x]` for complete)
- Identify which tasks have been completed since the last review request
- Only proceed if at least one task has been completed since the last review OR if triggered by `/review` command

### 4. Rate Limiting Check

If this is NOT a `/review` command:
- Check the timestamp of the last review request or review-related comment
- If a review was requested less than 2 hours ago, skip this workflow run
- Log a message indicating the rate limit was hit

### 5. Determine Reviewer

Identify the reviewer to request:
- Check PR labels for a designated reviewer
- Look for `CODEOWNERS` file patterns
- Use the repository's default reviewers if configured
- If no reviewer is specified, use a default or skip

### 6. Find Last Reviewed Commit

Search through PR comments to find the last review or review request:
- Look for previous comments from this workflow
- Check review submission events
- Extract the commit SHA that was last reviewed
- If no previous review exists, use the first commit of the PR

### 7. Generate Review Request Comment

Generate a comment to be posted on the PR via safe outputs with:
- Tag the reviewer using `@username`
- A link to view changes since the last reviewed commit using the format:
  `https://github.com/{owner}/{repo}/pull/{pr_number}/files/{last_reviewed_sha}..{current_sha}`
- If tasks were completed, list them in a bullet point format
- Include a friendly message about what has changed

Example comment format:
```
@reviewer - Review requested!

**Changes since last review:**
View the changes here: [Compare {short_sha}..{short_sha}](https://github.com/{owner}/{repo}/pull/{pr_number}/files/{last_sha}..{current_sha})

**Completed tasks since last review:**
- [x] Task 1 description
- [x] Task 2 description

All checks are passing ✓
```

The comment will be automatically posted via the `add-comment` safe output, which will also hide previous comments from this workflow to keep the PR timeline clean.

### 8. Request the Review

Request a review from the identified reviewer(s) via the `add-reviewer` safe output. This will formally request the review through the permission-controlled execution layer, maintaining security through the least privilege model.

## Error Handling

- If checks are not passing, do not request a review and post a comment explaining why
- If no reviewer can be identified, log a warning but do not fail
- If rate limited, skip silently (no comment needed)
- If API calls fail, retry once before failing

## Security Considerations

- Uses safe outputs for all write operations (comments and reviewer assignments)
- Agent runs with read-only permissions; write operations execute in separate permission-controlled jobs
- Defense against prompt injection through structured output validation
- All operations are auditable and logged
- Rate limiting prevents abuse
- Do not expose sensitive information in comments
- Controlled limits: maximum 1 comment and 3 reviewers per workflow run
