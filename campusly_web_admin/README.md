# Campusly Admin Portal

Build a modern, production-ready Admin Dashboard called "Campusly Admin".

Tech Stack:

- React + TypeScript

- Next.js 15 (App Router)

- Tailwind CSS

- shadcn/ui

- React Hook Form

- Zod Validation

- Firebase Authentication

- Firestore Database

- Firebase Storage

- TanStack Query

- Framer Motion

- Lucide Icons

Theme:

- Minimal

- Modern

- Clean

- Professional

- Apple-inspired

- Large spacing

- Soft shadows

- Rounded cards

- Responsive

- Light & Dark Mode

- Primary color: #2563EB

- Secondary: Slate

- No unnecessary gradients

- No glassmorphism

- Focus on usability

================================================

SYSTEM OVERVIEW

This dashboard is used by colleges to manage everything inside Campusly.

The mobile app never creates academic data.

Everything is managed here.

Changes made here instantly reflect inside the student mobile app through Firebase.

================================================

LOGIN SYSTEM

Create a secure login page.

Features:

- Google Sign In

- Email + Password

- Forgot Password

- Firebase Authentication

- Only admins can login

- After login check admin collection

- Unauthorized users should be blocked

- Remember Login

- Loading State

- Error State

Collections:

admins

Fields

uid

name

email

photo

role

collegeId

permissions

createdAt

================================================

LAYOUT

Sidebar

Dashboard

Students

Faculty

Departments

Courses

Academic Years

Semesters

Sections

Subjects

Classrooms

Timetable

Attendance

Assignments

Resources

Events

Clubs

Notifications

Exam Schedule

Holiday Calendar

Settings

Profile

Logout

Top Navigation

Search

Notifications

Dark Mode Toggle

Profile Menu

================================================

DASHBOARD

Create beautiful analytics cards.

Cards

Total Students

Total Faculty

Departments

Subjects

Assignments

Events

Notifications

Upcoming Exams

Charts

Students per Department

Attendance Overview

Assignments Submitted

Recent Activities

Latest Notifications

Today's Classes

Upcoming Events

================================================

STUDENTS MODULE

Student Table

Search

Filter

Pagination

Import CSV

Export CSV

Add Student

Edit Student

Delete Student

Profile View

Fields

Student ID

Roll Number

Name

Email

Phone

Department

Course

Academic Year

Semester

Section

Photo

Address

Guardian

Status

================================================

FACULTY MODULE

Faculty CRUD

Fields

Faculty ID

Name

Email

Department

Designation

Phone

Photo

Subjects

Status

================================================

DEPARTMENTS

CRUD

Department Name

Department Code

Description

Head of Department

================================================

COURSES

CRUD

Example

B.Tech

MBA

MCA

================================================

ACADEMIC YEARS

CRUD

2026-2027

2027-2028

================================================

SEMESTERS

CRUD

Semester Number

Start Date

End Date

================================================

SECTIONS

CRUD

Section Name

Department

Year

Semester

Strength

================================================

SUBJECTS

CRUD

Subject Code

Subject Name

Credits

Department

Semester

Faculty

================================================

CLASSROOMS

CRUD

Room Number

Building

Capacity

================================================

TIMETABLE MODULE

Weekly timetable

Monday

Tuesday

Wednesday

Thursday

Friday

Saturday

Each Period

Start Time

End Time

Subject

Faculty

Classroom

Department

Semester

Section

Drag and Drop Editor

Duplicate Timetable

Export PDF

================================================

ATTENDANCE

Attendance Analytics

View by

Student

Department

Section

Subject

Faculty

Percentage

Daily

Monthly

Semester

================================================

ASSIGNMENTS

Create Assignment

Title

Description

Due Date

Subject

Faculty

Department

Semester

Section

Attachment Upload

Status

================================================

RESOURCES

Upload

PDF

Notes

Books

PPT

Videos

Previous Year Papers

Lab Manuals

Firebase Storage

================================================

EVENTS

Create Event

Poster

Title

Venue

Date

Time

Registration Link

Description

Target Audience

================================================

CLUBS

Club Name

Description

Poster

Faculty Coordinator

Registration Link

================================================

NOTIFICATIONS

Create Notification

Title

Description

Priority

Target

Entire College

Department

Semester

Section

Push Notification Ready

================================================

EXAMS

Exam Name

Department

Semester

Section

Subject

Date

Time

Venue

================================================

HOLIDAY CALENDAR

Holiday Name

Date

Description

================================================

PROFILE

Photo

Name

Email

Change Password

================================================

SETTINGS

College Information

Logo

College Name

Address

Email

Phone

Website

Timezone

Theme

================================================

DATABASE STRUCTURE

admins

students

faculty

departments

courses

academicYears

semesters

sections

subjects

classrooms

timetable

attendance

assignments

resources

events

clubs

notifications

examSchedule

holidays

settings

================================================

FIREBASE

Authentication

Firestore

Storage

Security Rules

Role Based Access

================================================

USER ROLES

Super Admin

Admin

Faculty

Read-only Admin

================================================

PERMISSIONS

View

Create

Edit

Delete

Export

Import

================================================

UI REQUIREMENTS

Every page should include:

Header

Breadcrumb

Search

Filters

Table

Pagination

Loading Skeleton

Empty State

Error State

Confirmation Dialogs

Success Toasts

Responsive Design

================================================

QUALITY

Generate clean reusable components.

Use Server Components where appropriate.

Use TypeScript everywhere.

Follow scalable folder structure.

Use reusable forms.

Use reusable data tables.

Create reusable modal components.

Create reusable confirmation dialogs.

Create reusable file uploader.

Create reusable cards.

Create reusable charts.

Create reusable Firebase services.

Create reusable hooks.

================================================

IMPORTANT

Do NOT use mock-only architecture.

Build the project with Firebase integration in mind.

Use proper Firestore collection names.

Design every page as if this dashboard will be used by thousands of colleges.

The UI should feel polished, fast, minimal, and production-ready.

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/d00b624c-8412-4be3-af8a-b760eff31e4d).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
