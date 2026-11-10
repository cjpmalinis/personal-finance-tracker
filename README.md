# Personal Finance Manager

A single-user, web-based personal finance tracker built with React, Vite and Supabase.

## Included
- Email/password sign-in
- Salary and other income records
- Payroll deductions: GSIS, Pag-IBIG, PhilHealth, G-Flex, E-Loan and other deductions
- Personal expense recording
- Loan accounts and estimated balances
- Monthly dashboard and annual summary
- CSV export for the current module and annual reports
- Responsive layout for desktop and mobile
- Supabase Row Level Security: each record is restricted to its owner

## 1. Create the Supabase cloud database
1. Create a project at https://supabase.com.
2. Open SQL Editor and run all of `supabase/schema.sql`.
3. In Project Settings > API, copy the Project URL and publishable/anon key.
4. In Authentication settings, turn off public sign-ups.
5. In Authentication > Users, create your single email/password account.

Do not use the `service_role` secret in this browser app.

## 2. Run locally
Install Node.js 20 or newer, then:

```bash
npm install
cp .env.example .env
```

Edit `.env` and add your Supabase URL and publishable/anon key:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY
```

Then run:

```bash
npm run dev
```

Open the local URL printed by Vite (usually http://localhost:5173).

## 3. Build for deployment
```bash
npm run build
```
The production site is generated in `dist/`.

You can deploy `dist/` to Vercel, Netlify or another static hosting provider. Add the same two environment variables in the hosting provider's project settings, then redeploy.

## Data and calculations
- Total income = salary + PERA + other income.
- Payroll deductions = GSIS + Pag-IBIG + PhilHealth + G-Flex + E-Loan + other deductions.
- Net salary = total income − payroll deductions.
- Remaining balance = net salary − personal expenses.
- Estimated loan balance = opening balance + new charges + interest/fees − linked debt payments.

Loan repayments are entered as expense records and linked to a loan in the "Link to loan" field. Only linked records reduce that loan's estimated balance.

## Important limitations in this starter version
- Records can be added and deleted; editing existing records is not yet included.
- CSV exports are provided; PDF export and automated bank syncing are not included.
- Monthly report figures use the date recorded on each transaction.
- The app does not contain your old Excel data automatically. Import/encoding of historical records should be done after the database is configured.
