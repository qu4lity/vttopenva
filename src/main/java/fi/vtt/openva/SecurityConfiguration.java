// OpenVA - Open software platform for visual analytics
//
// Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//    1) Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//    2) Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//    3) Neither the name of the VTT Technical Research Centre of Finland nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package fi.vtt.openva;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.security.SecurityProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.DefaultRedirectStrategy;
import org.springframework.security.web.RedirectStrategy;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;

/**
 * SecurityConfiguration.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */

@Configuration
@EnableWebSecurity
@Order(SecurityProperties.DEFAULT_FILTER_ORDER)
public class SecurityConfiguration extends WebSecurityConfigurerAdapter {
	
	private RedirectStrategy redirectStrategy = new DefaultRedirectStrategy();
	@Value("${server.servlet.session.timeout}")
	private Integer timeout;
	
    //@Override
    protected void configure(HttpSecurity http) throws Exception {                
          http
          	.authorizeRequests()
           		.antMatchers("/img/**").permitAll()
           		.antMatchers("/css/**").permitAll()
           		.anyRequest().fullyAuthenticated()
            .and()
           		.sessionManagement()
           		.maximumSessions(1)
           	.and()
           		.invalidSessionUrl("/login.html?expired")
           	.and()
           		.formLogin()
           		.loginPage("/login.html")
           		.successHandler(new AuthenticationSuccessHandler() {
           	    @Override
           	    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
           	            Authentication authentication) throws IOException, ServletException {
           					request.getSession().setMaxInactiveInterval(timeout);
           	        redirectStrategy.sendRedirect(request, response, "/");
           	    	}
           		})
           		.permitAll()
           	.and()
           		.logout()
           		.logoutUrl("/logout")
          		.logoutSuccessUrl("/login.html?logout")
          		.permitAll();
        
         http.csrf().disable();  

          http.headers()
  			.frameOptions().sameOrigin()
  			.httpStrictTransportSecurity().disable();
    	}
    
    public static Authentication getAuthentication() {
        return SecurityContextHolder.getContext().getAuthentication();
    }  
     
    @Bean
    public BCryptPasswordEncoder passwordEncoder(){
        return new BCryptPasswordEncoder();
    }
}