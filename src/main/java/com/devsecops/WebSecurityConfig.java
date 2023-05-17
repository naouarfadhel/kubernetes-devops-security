package com.devsecops;

import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import com.sun.xml.ws.developer.JAXWSProperties;

@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    @SuppressWarnings("squid:S4430")
    protected void configure(HttpSecurity http) throws Exception {

        http.csrf().disable();
    }
}
