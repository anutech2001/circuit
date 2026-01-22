package com.example.adapter_service;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.concurrent.CompletableFuture;

@Service
public class ExternalApiClient {

    private final RestClient restClient;

    public ExternalApiClient(RestClient.Builder builder) {
        this.restClient = builder
                .baseUrl("http://localhost:8080")
                .build();
    }

    @Bulkhead(name = "externalApi")
    @CircuitBreaker(name = "externalApi", fallbackMethod = "fallback")
    @TimeLimiter(name = "externalApi")
    @Retry(name = "externalApi")
    public CompletableFuture<String> callExternal(String mode) {
        return CompletableFuture.supplyAsync(() ->
                restClient.get()
                        .uri("/external/" + mode)
                        .retrieve()
                        .body(String.class)
        );
    }

    private CompletableFuture<String> fallback(String mode, Throwable ex) {
        return CompletableFuture.completedFuture("FALLBACK");
    }
}