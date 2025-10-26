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

import { RegisterUserWidget } from "@/widgets/user/Register";

export default function RegisterModal() {
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
        <DialogTitle>Sign up</DialogTitle>
        <DialogDescription>
          Create an account to get started! If you have already an account, you
          can sign in{" "}
          <Link href="/login" replace>
            <span className="text-blue-500 hover:underline">here</span>
          </Link>
          .
        </DialogDescription>
        <RegisterUserWidget
          formId={formId}
          onStartLoading={setIsLoading.bind(null, true)}
          onStopLoading={setIsLoading.bind(null, false)}
          onSuccess={() => {
            toast.success("Signed up successfully.");
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
            Register
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
