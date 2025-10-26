"use client";
import confetti from "canvas-confetti";
import { toast } from "sonner";
import { useLayoutEffect, useState, useTransition } from "react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

import { getFlag } from "@/core/flag/get";
import { FLAG_PRICE } from "@/data/config";
import { useAuthContext } from "@/lib/auth/Context";

export function PurchaseFlagButton() {
  const [flag, setFlag] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  useLayoutEffect(() => {
    if (!flag) {
      return;
    }

    const duration = 5 * 1000;
    const animationEnd = Date.now() + duration;
    const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };
    const randomInRange = (min: number, max: number) =>
      Math.random() * (max - min) + min;
    const interval = window.setInterval(() => {
      const timeLeft = animationEnd - Date.now();
      if (timeLeft <= 0) {
        return clearInterval(interval);
      }
      const particleCount = 50 * (timeLeft / duration);
      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 },
      });
      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 },
      });
    }, 250);
  }, [flag]);

  const [authState] = useAuthContext();
  if (!authState) {
    return null;
  }
  if (authState.balance < FLAG_PRICE) {
    return (
      <Tooltip>
        <TooltipTrigger>
          <Button variant="outline" disabled>
            Get flag
          </Button>
        </TooltipTrigger>
        <TooltipContent>
          You need at least {FLAG_PRICE} coins to get the flag.
        </TooltipContent>
      </Tooltip>
    );
  }

  return (
    <Dialog open={!!flag} onOpenChange={() => setFlag(null)}>
      <DialogTrigger asChild>
        <Button
          variant="outline"
          type="submit"
          onClick={() => {
            startTransition(async () => {
              const result = await getFlag();
              if ("flag" in result) {
                setFlag(result.flag);
                return;
              }
              toast.error(result.error ?? "Something went wrong…");
            });
          }}
          disabled={isPending}
        >
          {isPending && <Spinner />}
          Get flag
        </Button>
      </DialogTrigger>
      <DialogContent>
        Congratulations! Your flag is: <code>{flag}</code>
      </DialogContent>
    </Dialog>
  );
}
