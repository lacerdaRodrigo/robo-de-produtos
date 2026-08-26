import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "API",
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return children;
}