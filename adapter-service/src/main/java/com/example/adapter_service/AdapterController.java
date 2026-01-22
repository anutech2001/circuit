package com.example.adapter_service;

import java.util.concurrent.CompletableFuture;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/adapter")
public class AdapterController {

    private final ExternalApiClient client;

    public AdapterController(ExternalApiClient client) {
        this.client = client;
    }

    @GetMapping("/{mode}")
    public CompletableFuture<String> call(@PathVariable String mode) {
        return client.callExternal(mode);
    }
}