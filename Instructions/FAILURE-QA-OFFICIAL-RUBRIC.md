# Olympus Diamond-Tier Task Guide

Diamond-tier tasks are higher quality tasks with additional requirements:

- Must use **Castor runs**. Requires 10+ runs with 1-5 successes.
- Requires failure QA:
  - This is to ensure that tests are fair.
  - If you find that the tests are unfair or underspecified for any reason in this process, **you need to fix it and re-run the pipeline**.

You can submit new diamond-tier tasks or convert tasks in draft or review into diamond-tier for a higher payout.

## Castor Runs

Unlike normal task submissions, only Castor runs are considered, which cost 10x more. We've given you extra tokens for this reason.

## Success Solution Explanation

Submit a high-level summary of the expected solution. Explain it at a high-level that a non-expert of the repo can understand. This will be used as context for understanding the solution.patch.

## Test Summary

For all the f2p (fail to pass) tests, group them into test groups. For each test group, explain what this test group tests and where in the description this requirement is mentioned. Quote parts of the task description for this summary. At the end, ensure that every requirement in the prompt is tested by at least one test group.

## Success Trajectory Analysis

Explain why the implementation is correct, why it meets all the requirements of the description, and does not cause regressions on existing behavior.

Then, if the implementation passes all tests but is not correct, and it is impossible to test this deterministically, provide a detailed explanation of the failure and why it is impossible to test this. For each issue, provide a severity score from 1-5 (4+ is blocking, 3 is borderline, 1-2 is non-blocking) and categorize it as one of correctness, design, extensibility, readability and instruction following.

## Failure QA Instructions

The goal of Olympus failure analysis is to assess submissions for **fairness**. If the agent fails a test, that failure should reflect a genuine mistake by the agent, not an ambiguous or underspecified task description. The agent should be able to infer the correct behavior from the prompt and codebase alone.

If you find in this process that a task is unfair or suboptimal for any reason, you need to **fix the prompt or verifier and re-run the pipeline**.

For **every test failure** on **every agent run**:

- **Unfairness check:** Validate that the failure was due to genuine suboptimal agent behaviour instead of ambiguous requirements. Would a seasoned engineer in this codebase not have made this same error? You should: explicitly cite snippets from the prompt, explain how the test case code _correctly_ validates the requirement, and if necessary, cite conventions from the codebase to explain any inferred requirements/nuance that the test case assumes.
- **Root cause analysis:** Pinpoint to exactly where in the trajectory this error is made and the type of error made. Did the agent make an incorrect assumption or did the agent miss an inferrable edge case? Cite snippets of the solution.

NOTE: A common failure mode is when requirements in the prompt contradict either 1) each other or 2) a strongly established code-based convention, which can lead the agent to choose to follow convention over the prompt. If you notice these, you should try to first fix the prompt/verifier to be aligned with the conventions, or if too difficult, use "hint"s to prompt the behavior being tested.

### Example

Bad Response:

- **Unfairness check:** This is an explicit requirement from the prompt "Zod formatter schemas require defaulted and linked attributes".
- **Root cause analysis:** The readLink requirement did not make it into Zod formatter optionality, whereas readDefault did.

Good Response:

**Unfairness check:** The test case is fair, since it validates a requirement explicitly specified in the prompt "Zod formatter schemas require defaulted and linked attributes". While the exact setup in the tests

+ label: string()

\+ .optional()

\+ .readLink&lt;typeof schema&gt;(({ pk }) => pk + '-label')

seems a bit contradictory, i.e., requiring a seemingly "optional" field to also be required, it is evident from the repo that the .optional() modifier here describes optionality of the field's value in the database (in other words, optional on write), while the readLink modifier obviously applies to reads. ZodFormatter, and formatters in general, have the role of parsing objects during read, so this behavior of "optional during write" / "required during read" is conventional and consistent.

**Root cause analysis:** Essentially, the agent handled the \`readDefault\` case properly but not the \`readLink\` case. In src/schema/actions/zodSchemer/formatter/utils.ts, the agent extended withOptional to check schema.props.readDefault and, when it's a static value, return zodSchema.default(readDefault) (this also happens to be incorrect logic, since thunk values should also be handled the same). However, it never added a check for schema.props.readLink, so when only readLink is present, the schema gets wrapped in z.optional(), i.e., does not become a required field.
