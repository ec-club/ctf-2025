<script setup lang="ts">
import SubmitSolutionForm from "~/widgets/SubmitSolutionForm.vue";
</script>

<template>
  <UContainer>
    <UCard class="max-w-lg mx-auto my-8" flat>
      <div class="p-6">
        <div class="mb-2">
          <UText as="h1" size="lg">Submit a solution</UText>
        </div>
        <UText size="sm" class="text-muted">
          So, write <UKbd>0</UKbd> if essay was written by
          <code>ggml-org/gemma-3-12b-it-qat-GGUF</code> and <UKbd>1</UKbd> if it
          was <code>ggml-org/gpt-oss-20b-GGUF</code>.
          <p>
            Solution format:
            <code>0111010101011</code>.
          </p>
        </UText>
        <section class="mt-6 w-full">
          <SubmitSolutionForm />
        </section>
      </div>
    </UCard>
  </UContainer>
</template>
