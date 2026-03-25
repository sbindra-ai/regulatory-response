# Lynkuet Hackathon Team 05 - User Manual & Developer Guide

Welcome to the comprehensive guide for the **AI-Powered Regulatory Response Accelerator for SPA**. This document serves as a one-stop reference for users, developers, and stakeholders to understand how the project was built, how it works, and how to scale it in the future.

---

## 1. What is this Project? (The MVP)
This repository is an **MVP (Minimum Viable Product)** created during a hackathon. 
An MVP is the most basic version of a product that has just enough features to be usable by early customers and provide feedback for future product development. 
Instead of building a massive, perfect enterprise application from day one, this MVP focuses strictly on proving the core concept: **taking unstructured regulatory questions (like FDA Information Requests) and using AI to build response plans and find relevant similar work.**

---

## 2. How Was This Repository Created?
This application relies on modern web development standards. It was built using:
- **Next.js (App Router):** A React framework that handles both the frontend (User Interface) and the backend (API and Server logic) in one single project.
- **TypeScript:** A strongly-typed version of JavaScript that helps catch errors during development.
- **Tailwind CSS & Shadcn UI:** For styling the beautiful components (buttons, dark mode, cards) quickly and uniformly.
- **OpenAI Node.js SDK:** Used to connect to the Bayer internal "myGenAssist" (MGA) AI endpoints instead of public ChatGPT endpoints.

---

## 3. Folder Structure: What Does Each Folder Do?

If you want to edit the code, you need to understand where everything lives:

* **`app/`**: This is the **Frontend Routing and Actions**. Every folder inside here represents a page or an API route on the website. (e.g., `app/page.tsx` is the main homepage).
* **`components/`**: This is the **Frontend UI**. All the visual puzzle pieces (Buttons, Forms, Copilot chat interfaces, Modals) live here. If you want to change how something looks, you edit files here.
* **`lib/`**: This is the **Backend Logic**. This folder is where the heavy lifting happens. It contains the code that talks to the AI, parses data, and enforces rules. 
  * `lib/server/copilot/`: Contains the specific workflows the AI uses (predicting questions, interpreting requests, generating plans).
  * `lib/server/llm/`: Contains the specific code connecting directly to the myGenAssist API.
* **`data/`**: Holds internal mock data and the `evidence-corpus.json` file which acts as the "searchable brain" for finding prior regulatory answers.
* **`docs/`**: Documentation, hackathon planning notes, and example files (like `.sas` programs or `define.xml`).
* **`scripts/`**: Useful utilities, like the script that converts the sample documents into the `evidence-corpus.json` brain.
* **`tests/`**: Automated code tests written with Vitest to ensure updates don't break the rules.

---

## 4. How to Make Changes (Frontend vs. Backend)

### Updating the Frontend (The Visuals/UI)
If you want to change the text, buttons, colors, or page layout:
1. Navigate to the `app/` folder to change page layouts (e.g., `app/page.tsx`).
2. Navigate to the `components/` folder to change reusable UI pieces. 
3. *Note: Frontend code is executed in the user's browser, so it focuses purely on display logic.*

### Updating the Backend (The AI & Logic)
If you want to change how the AI interprets questions, how it searches for documents, or which external services it calls:
1. Navigate to the `lib/` folder.
2. If you want to change the **System Prompt** (the hidden instructions given to the AI), look for files inside `lib/server/copilot/prompts.ts` or similar files. 
3. If you want to add a new database connection or new API endpoint, create those inside `lib/server`.
4. *Note: Backend code handles secrets (like the MGA token) and heavy processing. This code runs securely on the Node.js server, not in the browser.*

---

## 5. What are MGA Tokens? Why Do We Need Them?

**What is a Token?**
In software, an API Token is essentially a long, secure password. It acts as an ID card that tells a secure system: *"I am allowed to be here, and here is my proof."*

**What is an MGA Token?**
"MGA" stands for **myGenAssist**, which is Bayer's secure, internal, enterprise version of an AI Large Language Model (similar to ChatGPT, but private and secure).
Because running AI requires expensive computing power and strict data privacy, the AI is locked behind a strict gateway. You cannot use the AI unless you provide it an MGA Token.

**Why do we need them?**
When the user types a regulatory question into the app, the app packages that question and sends it to `chat.int.bayer.com/api/v2`. To prove the app is authorized to ask the question, it attaches the user's **MGA Token** to the invisible request. Without it, the Bayer server will reject the request with an error, which is why the application stops working when it is missing.

---

## 6. How to Scale the Application Further
Currently, this is a prototype (MVP) using static documents and the local file system. If the team decides to turn this into an official Enterprise application, here are the steps for scaling:
1. **Move to a Vector Database:** Instead of storing the knowledge brain in a single `evidence-corpus.json` file, you would integrate a cloud Vector Database (like Pinecone, Milvus, or pgvector) so you can instantly search through tens of thousands of real documents without slowing down the application.
2. **Implement User Authentication (SSO):** Instead of making the user manually paste their MGA Token, integrate with Azure AD or Bayer's Single Sign-On. When an employee logs in, the app automatically authenticates them in the background.
3. **Live Document Ingestion Pipeline:** Create an automated worker that automatically scans new internal SharePoint folders or Documentum systems every night, converting new regulatory SAPs and protocols into the AI's searchable brain automatically.
4. **Deploy to Cloud Infrastructure:** Host the application on AWS, Azure, or internal Kubernetes clusters rather than running it locally via `start-dev.bat`.

---

## 7. Step-by-Step Local Environment Guide

If a new team member joins tomorrow, here is exactly how they get the project running locally:

**Prerequisites:**
1. Have Git installed.
2. Have Node.js (v20+ or v22 LTS) installed.

**Setup Instructions:**
1. Clone the repository.
2. Open your terminal in the project folder.
3. Run `npm install` to download all necessary web packages and dependencies (like Next.js and Tailwind).
4. Run `npm run ingest` to build the required local knowledge base (this creates the `evidence-corpus.json` file from the sample `/docs`).
5. Run `npm run dev` to start the local development server.
6. Open your web browser and navigate to `http://localhost:3000`.
7. Once the app loads, open the **Settings** menu and paste your active **myGenAssist Token**.
8. (Optional) Run `npm run test` to verify that all the backend logic tests are passing.

*For users without administrative PC rights, use the provided `start-dev.bat` file to use a portable version of Node.js for local testing!*
