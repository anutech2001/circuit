package com.example.external_mock_service;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/external")
public class ExternalController {

    @GetMapping("/ok")
    public String ok() {
        return "OK";
    }

    @GetMapping("/slow")
    public String slow() throws InterruptedException {
        Thread.sleep(3000);
        return "SLOW";
    }

    @GetMapping("/timeout")
    public String timeout() throws InterruptedException {
        Thread.sleep(10000);
        return "TIMEOUT";
    }

    @GetMapping("/error")
    public ResponseEntity<String> error() {
        return ResponseEntity.status(500).body("ERROR");
    }
}