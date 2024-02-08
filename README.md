# Work in progress, everything is subject to change.

This project is early development, but if you want to contribute -
_idk why anyone would but thanks_ - feel free to create issues.

Please do **not** use it in production.

The latest version is running at [ResMon.de](https://resmon.de).

---

# What is ResMon?

## (Or rather: What should ResMon be?)

ResMon stands for **Res**ource **Mon**itor. The genesis of this project occurred during a university project, highlighting the need for a straightforward work time tracking tool. Particularly for those who freelance or undertake side projects, having a rudimentary means to gauge time expenditure is invaluable. Thus, the concept of a simplistic work time tracking application was conceived.

But why restrict ourselves? Knowing your total work duration is one thing, but how about delineating the time spent on project A versus project B? Incorporating basic project management features could enable tracking of time based on the specific project at hand. Delving deeper, segmenting a project into parts, sub-parts, and individual tasks affords clarity on achievements and pending objectives.
By tagging tasks with labels such as `Architecture`, `Frontend`, `Backend`, `Database Design`, etc., you gain insights into where your time is allocated. Adding notes provides context, and a rating system on task outcomes or satisfaction levels offers a deeper understanding of preferences and aversions.

As a freelancer developing custom tools to streamline your workflow, the question arises: How do you bill for the time invested in these tools? Estimating the time saved through your innovations allows for their cost to be factored into final invoices. After employing your tool across several projects, the return on investment becomes apparent, contingent on tracking both the development time and the time saved.

Furthermore, generating invoices for clients becomes streamlined with a project management tool that also logs your time. And considering the administrative tasks inherent to self-employment, ResMon can account for these as separate projects, enabling an accurate calculation of indirect costs to be billed to clients. For instance, business lunches or the use of a personal vehicle for work purposes can be recorded and factored into project expenses within ResMon. Such meticulous tracking ensures that all aspects of project-related expenditure and effort are compensated.

On the topic of vehicle use for client services, including refueling costs as project expenses in ResMon, alongside documenting the job through photographs, provides a robust basis for future queries. Recording travel distances and time contributes to a comprehensive expense report, facilitating seamless inclusion in client invoices and tax filings.

After a period of self-employment, evaluating the profitability of hardware and tool investments becomes crucial. ResMon's ability to track these expenses per project assists in informed decision-making regarding future expenditures. An integrated inventory management system further aids in monitoring hardware stock levels, costs, and selling prices to ensure profitability. Additionally, reviewing recent work patterns, earnings, and average hourly rates can safeguard against overwork and ensure fair compensation.

In summary, ResMon aims to be an indispensable tool for independent professionals managing projects. It's designed to autonomously track your activities, expenses, and achievements—privately and transparently. By simplifying the tracking of your endeavors and finances, ResMon enables you to ascertain the value of your time and investments.

Don't squander your resources, especially the most precious one: **time**. Keep track of them with **ResMon**.

---

# Requirements:

-   [Go](https://go.dev/dl/)
-   [Elm](https://guide.elm-lang.org/install/elm.html)
-   [Node.js](https://nodejs.org/)

You need to install NPM Dependencies with: `npm install`.

## Elm-Review:

`npm run review`

## Testing:

`npm run test`

## Developing

`npm run dev`

## Generating

`npm run generate`

## Building

`npm run build`
