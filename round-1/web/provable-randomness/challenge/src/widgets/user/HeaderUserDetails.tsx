"use client";
import Link from "next/link";

import { useAuthContext } from "@/lib/auth/Context";

import { cn } from "@/lib/utils";

import { Button } from "@/components/ui/button";

import { PurchaseFlagButton } from "./PurchaseFlagButton";

export function HeaderUserDetails({ className }: { className?: string }) {
  const [authState] = useAuthContext();
  if (!authState) {
    return (
      <div className={cn("flex gap-2", className)}>
        <Link href="/register">
          <Button variant="secondary">Sign up</Button>
        </Link>
        <Link href="/login">
          <Button>Sign in</Button>
        </Link>
      </div>
    );
  }
  return (
    <div className={cn("flex gap-6 items-center", className)}>
      <div className="flex flex-col text-white">
        <p>Welcome, {authState.username}!</p>
        <p>Balance: {authState.balance}</p>
      </div>
      <PurchaseFlagButton />
    </div>
  );
}
