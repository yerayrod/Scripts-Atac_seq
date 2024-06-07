#!/bin/bash

# Directorios de trabajo
RAW_DATA_DIR="raw_data"
QUALITY_PRE_DIR="quality_pre"
TRIMMING_DIR="trimming"
QUALITY_POS_DIR="quality_pos"

# Crear los directorios si no existen
mkdir -p $QUALITY_PRE_DIR
mkdir -p $TRIMMING_DIR
mkdir -p $QUALITY_POS_DIR

# Mueve al directorio de datos crudos
cd $RAW_DATA_DIR

#Solicita la longitud de trimming al usuario
read -p "Introduce la longitud mínima de lectura deseada para el trimming(-l): " min_length

# Análisis de calidad inicial con FastQC
echo "Iniciando primer control de calidad..."
fastqc *.fq.gz -t 12 -o ../$QUALITY_PRE_DIR

# Generar reporte inicial con MultiQC
echo "Generando reporte MultiQC..."
cd ../$QUALITY_PRE_DIR
multiqc .

# Volver al directorio de datos crudos
cd ../$RAW_DATA_DIR

# Trimming con fastp

for file in *_1.fq.gz
do
  base=$(basename $file _1.fq.gz)
  forward="${base}_1.fq.gz"
  reverse="${base}_2.fq.gz"
  trimmed_forward="../$TRIMMING_DIR/${base}_1_trim.fq.gz"
  trimmed_reverse="../$TRIMMING_DIR/${base}_2_trim.fq.gz"
  report_html="../$TRIMMING_DIR/${base}_report_fastp.html"
  report_json="../$TRIMMING_DIR/${base}_report_fastp.json"

  echo "Trimming muestra $forward y su reverse $reverse..."
  fastp -i $forward -I $reverse -o $trimmed_forward -O $trimmed_reverse --trim_poly_g --detect_adapter_for_pe -l $min_length -h $report_html -j $report_json
done

# Análisis de calidad final con FastQC
echo "Iniciando control de calidad postprocesado..."
fastqc ../$TRIMMING_DIR/*_trim.fq.gz -t 12 -o ../$QUALITY_POS_DIR

# Generar reporte final con MultiQC
echo "Generando reporte MultiQC..."
cd ../$QUALITY_POS_DIR
multiqc .

echo "Proceso completado. Los resultados están en $QUALITY_PRE_DIR, $TRIMMING_DIR, y $QUALITY_POS_DIR."
