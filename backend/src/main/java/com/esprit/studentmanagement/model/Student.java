package com.esprit.studentmanagement.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;

@Entity
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Le nom est obligatoire")
    @Size(min = 2, max = 50, message = "Le nom doit contenir entre 2 et 50 caractères")
    @Pattern(regexp = "^[A-Za-zÀ-ÿ\\s-]+$", message = "Le nom ne doit contenir que des lettres")
    private String nom;

    @NotBlank(message = "L'email est obligatoire")
    @Pattern(regexp = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
            message = "Format d'email invalide (ex: nom@domaine.com)")
    private String email;

    @NotNull(message = "La note est obligatoire")
    @DecimalMin(value = "0.0", message = "La note ne peut pas être négative")
    @DecimalMax(value = "20.0", message = "La note ne peut pas dépasser 20")
    private Double note;

    public Student() {}

    public Student(String nom, String email, Double note) {
        this.nom = nom;
        this.email = email;
        this.note = note;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public Double getNote() { return note; }
    public void setNote(Double note) { this.note = note; }
}