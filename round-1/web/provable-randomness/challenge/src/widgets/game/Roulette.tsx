"use client";
import z from "zod";
import Link from "next/link";
import { toast } from "sonner";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRef, useState } from "react";
import { AlertCircleIcon, CheckCircle2Icon } from "lucide-react";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Roulette, RouletteController } from "@/components/Roulette";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";

import { useAuthContext } from "@/lib/auth/Context";

import { placeBet } from "@/core/game/bet";
import { betSchema } from "@/core/game/bet.schema";

export function RouletteWidget() {
  const rouletteRef = useRef<RouletteController>(null);
  const form = useForm({
    resolver: zodResolver(betSchema),
    reValidateMode: "onSubmit",
  });

  const [lastSpinState, setLastSpinState] = useState<{
    win: boolean;
    roundSeed: string;
  } | null>(null);
  const [_, setAuthState] = useAuthContext();
  async function onSubmit(data: z.infer<typeof betSchema>) {
    setLastSpinState(null);
    const result = await placeBet(data);
    if ("error" in result) {
      toast.error(result.error);
      return;
    }
    setTimeout(async () => {
      await rouletteRef.current?.spinTo(result.spinResult);
      setAuthState((prev) =>
        prev
          ? {
              username: prev.username,
              balance: result.newBalance,
            }
          : null
      );
      setLastSpinState({ win: result.win, roundSeed: result.roundSeed });
    }, 0);
  }
  return (
    <>
      <Roulette ref={rouletteRef} />
      <section className="mt-4 text-white flex flex-wrap">
        <div className="w-full flex flex-wrap justify-around">
          <aside className="flex flex-col gap-2">
            <h2 className="text-xl">Spin a wheel</h2>
            <ul>
              <li>
                Red or black -{" "}
                <span className="text-amber-500 font-bold">2x</span>
              </li>
              <li>
                Green - <span className="text-emerald-500 font-bold">7x</span>
              </li>
            </ul>
          </aside>
          <Form {...form}>
            <form
              onSubmit={form.handleSubmit(onSubmit)}
              className="flex flex-col gap-4"
            >
              <FormField
                control={form.control}
                name="color"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Color</FormLabel>
                    <FormControl>
                      <RadioGroup
                        onValueChange={field.onChange}
                        value={field.value}
                      >
                        <FormItem className="flex items-center space-x-2">
                          <FormControl>
                            <RadioGroupItem value="red" />
                          </FormControl>
                          <FormLabel>Red</FormLabel>
                        </FormItem>
                        <FormItem className="flex items-center space-x-2">
                          <FormControl>
                            <RadioGroupItem value="black" />
                          </FormControl>
                          <FormLabel>Black</FormLabel>
                        </FormItem>
                        <FormItem className="flex items-center space-x-2">
                          <FormControl>
                            <RadioGroupItem value="green" />
                          </FormControl>
                          <FormLabel>Green</FormLabel>
                        </FormItem>
                      </RadioGroup>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="amount"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Amount</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={1}
                        {...field}
                        onChange={(event) =>
                          field.onChange(parseInt(event.target.value))
                        }
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" disabled={form.formState.isSubmitting}>
                {form.formState.isSubmitting && <Spinner />}
                Spin
              </Button>
            </form>
          </Form>
        </div>
        {lastSpinState && (
          <Alert className="mt-4">
            {lastSpinState.win ? <CheckCircle2Icon /> : <AlertCircleIcon />}
            <AlertTitle>
              {lastSpinState.win ? "You won!" : "You lost!"}
            </AlertTitle>
            <AlertDescription>
              Do you want to know how the result was determined? Check out our
              article about{" "}
              <Link href="/fair-game">
                <span className="underline">fair game</span>.
              </Link>{" "}
              Round seed: <code>{lastSpinState.roundSeed}</code>
            </AlertDescription>
          </Alert>
        )}
      </section>
    </>
  );
}
