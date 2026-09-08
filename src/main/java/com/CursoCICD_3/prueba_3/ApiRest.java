package com.CursoCICD_3.prueba_3;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController                  // 👈 Permite devolver datos directos (JSON/Texto)
@RequestMapping("/api")          // 👈 Ruta base para todos los endpoints de esta clase
public class ApiRest {

	
	@GetMapping("/miSaludo")
	public String saludar()
	{
		return "Hola que tal";
	}
 
	@GetMapping("/miSaludo2")
	public String saludar2()
	{
		return "Hola que tal";
	}
}
