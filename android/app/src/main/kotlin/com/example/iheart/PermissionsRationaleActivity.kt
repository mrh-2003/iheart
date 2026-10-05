package com.example.iheart

import android.app.Activity
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView

class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Uso de datos de salud en IHeart"
        val texto = TextView(this).apply {
            textSize = 18f
            setPadding(32, 32, 32, 32)
            text = "IHeart solicita acceso de lectura a frecuencia cardíaca, frecuencia " +
                "en reposo, oxígeno en sangre, presión arterial, pasos y variabilidad " +
                "cardíaca para mostrar registros disponibles en Health Connect.\n\n" +
                "Los permisos de cada tipo son opcionales. Puede modificarlos o " +
                "revocarlos en Salud conectada > Permisos de aplicaciones > iheart.\n\n" +
                "La lectura de prueba solicita escritura de frecuencia cardíaca " +
                "por separado e inserta un dato manual de 76 bpm. Ese dato es sintético " +
                "y no representa una medición de su reloj.\n\n" +
                "Las sesiones y los diagnósticos se guardan en la base de datos local. " +
                "El backend gestiona autenticación y modelos.\n\n" +
                "La ausencia de registros no significa riesgo bajo. Las estimaciones " +
                "de la aplicación no reemplazan la evaluación de un profesional de salud."
        }
        setContentView(ScrollView(this).apply { addView(texto) })
    }
}
