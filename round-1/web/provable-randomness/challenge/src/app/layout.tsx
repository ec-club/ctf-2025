import Link from "next/link";
import { ReactNode } from "react";

import "./globals.css";

import { AuthProvider } from "@/lib/auth/Provider";

import { Toaster } from "@/components/ui/sonner";
import { HeaderUserDetails } from "@/widgets/user/HeaderUserDetails";

export default function RootLayout({
  children,
  modal,
}: {
  children: ReactNode;
  modal: ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-gray-900">
        <AuthProvider>
          <header className="mx-auto p-4 flex justify-between items-center gap-4 *:cursor-pointer">
            <Link href="/">
              <h1 className="text-2xl font-bold text-white">
                Provable Randomness
              </h1>
            </Link>
            <HeaderUserDetails />
          </header>
          {modal}
          {children}
        </AuthProvider>
        <Toaster />
        <footer className="p-4 flex flex-col items-center text-white">
          <span>&copy; {new Date().getFullYear()} Provable Randomness</span>
          <nav>
            <Link href="/fair-game" className="underline">
              Fair Game
            </Link>
          </nav>
        </footer>
      </body>
    </html>
  );
}
