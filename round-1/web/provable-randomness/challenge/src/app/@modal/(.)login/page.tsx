"use client";
import Link from "next/link";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import { useId, useState } from "react";

import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";

import { LoginWidget } from "@/widgets/user/Login";

export default function LoginModal() {
  const router = useRouter();
  const formId = useId();
  const [isLoading, setIsLoading] = useState(false);
  return (
    <Dialog
      open
      onOpenChange={() => {
        if (!isLoading) {
          router.back();
        }
      }}
    >
      <DialogContent>
        <DialogTitle>Log in</DialogTitle>
        <DialogDescription>
          Don&apos;t have an account? Sign up
          <Link href="/register" replace>
            <span className="text-blue-500 hover:underline">here</span>
          </Link>
          .
        </DialogDescription>
        <LoginWidget
          formId={formId}
          onStartLoading={setIsLoading.bind(null, true)}
          onStopLoading={setIsLoading.bind(null, false)}
          onSuccess={() => {
            toast.success("Logged in successfully.");
            router.back();
          }}
        />
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline" disabled={isLoading}>
              Cancel
            </Button>
          </DialogClose>
          <Button type="submit" form={formId} disabled={isLoading}>
            {isLoading && <Spinner />}
            Log in
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
