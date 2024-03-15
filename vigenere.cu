#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda_runtime.h>

#define MAX_SIZE 1000000 // Taille maximale pour le texte et la clé
#define MAX_KEY_SIZE 1000000


//kernel qui encode le texte
__global__ void encrypt_kernel(const char *cleartext, const char *key, char *ciphertext, int text_len, int key_len) {
    //calcul du numéro de la case sur laquelle l'itération travaille
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < text_len) {
        char c = cleartext[idx];
        //si la lettre à encoder est minuscule
        if (c >= 'a' && c <= 'z') {
            //on ajoute la valeur de la lettre de la clé à la valeur de la lettre à coder
            //on fait ensuite modulo 26 pour avoir la nouvelle lettre codée
            c = ((c - 'a') + (key[idx % key_len] - 'a')) % 26 + 'a';
        } else if (c >= 'A' && c <= 'Z') {
            c = ((c - 'A') + (key[idx % key_len] - 'a')) % 26 + 'A';
        }
        ciphertext[idx] = c;
    }
}

void cipher(const char *cleartext, const char *key, char *ciphertext) {
    //récupération de la taille du texte et de la clé pour les malloc et memcpy
    int cleartext_len = strlen(cleartext);
    int key_len = strlen(key);

    //définition des tableaux de charactère dans le GPU
    char *d_cleartext, *d_key, *d_ciphertext;

    //allocation de la mémoire pour les tableau stockés dans le GPU
    cudaMalloc((void **)&d_cleartext, (cleartext_len + 1) * sizeof(char));
    cudaMalloc((void **)&d_key, (key_len + 1) * sizeof(char));
    cudaMalloc((void **)&d_ciphertext, (cleartext_len + 1) * sizeof(char));

    //copie du texte dans la variable GPU
    cudaError_t status =cudaMemcpy(d_cleartext, cleartext, (cleartext_len + 1) * sizeof(char), cudaMemcpyHostToDevice);
    if (status != cudaSuccess) {
        printf("Erreur lors de la copie de d_cleartext vers le GPU : %s\n", cudaGetErrorString(status));
    }

    //copie de la clé dans la variable GPU
    status =cudaMemcpy(d_key, key, (key_len + 1) * sizeof(char), cudaMemcpyHostToDevice);
    if (status != cudaSuccess) {
        printf("Erreur lors de la copie de d_key vers le GPU : %s\n", cudaGetErrorString(status));
    }

    //appel du kernel. la première valeure correspond au nombre de blocs à appeler, la deuxième au nombre de thread par bloc
    encrypt_kernel<<<(cleartext_len + 255) / 256, 256>>>(d_cleartext, d_key, d_ciphertext, cleartext_len, key_len);
    //avec cette fonction, le code CPU va attendre que le code gpu ait fini de tourner
    cudaDeviceSynchronize();
    //copie du texte encodé dans la mémoire CPU
    cudaMemcpy(ciphertext, d_ciphertext, (cleartext_len + 1) * sizeof(char), cudaMemcpyDeviceToHost);


    //libération de la mémoire
    cudaFree(d_cleartext);
    cudaFree(d_key);
    cudaFree(d_ciphertext);

    //ajout du caractère nul à la fin du texte
    ciphertext[cleartext_len] = '\0'; 
}

int main()
{

    char cleartext[MAX_SIZE], key[MAX_KEY_SIZE], ciphertext[MAX_SIZE];

    FILE *plaintextFile = fopen("plaintext.txt", "r");
    if (plaintextFile == NULL)
    {
        perror("Error opening plaintext.txt");
        return 1;
    }
    int cleartextSize = fread(cleartext, 1, MAX_SIZE, plaintextFile);
    fclose(plaintextFile);

    FILE *keyFile = fopen("key.txt", "r");
    if (keyFile == NULL)
    {
        perror("Error opening key.txt");
        return 1;
    }

    int keySize = fread(key, 1, MAX_SIZE, keyFile);
    fclose(keyFile);

    cleartext[cleartextSize] = '\0';
    key[keySize] = '\0';

    //utilisation de cuda event pour calculer le temp d'exécution
    cudaEvent_t start, stop;
    float elapsedTime;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    //récupération de "l'heure" au début du code
    cudaEventRecord(start, 0);

    cipher(cleartext, key, ciphertext);
    

    FILE *ciphertextFile = fopen("ciphertext.txt", "w");
    if (ciphertextFile == NULL)
    {
        perror("Error opening ciphertext.txt for writing");
        return 1;
    }
    //récupération de "l'heure" à la fin du code
    cudaEventRecord(stop, 0);
    //synchronisation du code avec l'event "stop" pour s'assurer que le temps calculé soit correct
    cudaEventSynchronize(stop);
    //calcul du temps d'exécution avec une fonction de la bibliothèque CUDA
    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Elapsed time: %f ms\n", elapsedTime);
    fwrite(ciphertext, 1, strlen(ciphertext), ciphertextFile);

    fclose(ciphertextFile);

    return 0;
}