package com.esprit.studentmanagement.controller;

import com.esprit.studentmanagement.model.Student;
import com.esprit.studentmanagement.repository.StudentRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/students")
public class StudentController {

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping
    public List<Student> getAll() {
        return studentRepository.findAll();
    }

    // ⚠️ VULNERABLE: SQL Injection (CWE-89) - à des fins pédagogiques (démo SAST)
    @GetMapping("/search")
    public List<Student> search(@RequestParam String nom) {
        String query = "SELECT * FROM student WHERE LOWER(nom) LIKE LOWER('%" + nom + "%') " +
                "OR LOWER(email) LIKE LOWER('%" + nom + "%') " +
                "OR CAST(note AS VARCHAR) LIKE '%" + nom + "%'";
        return jdbcTemplate.query(query, (rs, rowNum) -> {
            Student s = new Student();
            s.setId(rs.getLong("id"));
            s.setNom(rs.getString("nom"));
            s.setEmail(rs.getString("email"));
            s.setNote(rs.getDouble("note"));
            return s;
        });
    }

    @GetMapping("/{id}")
    public Optional<Student> getById(@PathVariable Long id) {
        return studentRepository.findById(id);
    }

    @PostMapping
    public Student create(@Valid @RequestBody Student student) {
        return studentRepository.save(student);
    }

    @PutMapping("/{id}")
    public Student update(@PathVariable Long id, @Valid @RequestBody Student updated) {
        Student student = studentRepository.findById(id).orElseThrow();
        student.setNom(updated.getNom());
        student.setEmail(updated.getEmail());
        student.setNote(updated.getNote());
        return studentRepository.save(student);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        studentRepository.deleteById(id);
    }
}