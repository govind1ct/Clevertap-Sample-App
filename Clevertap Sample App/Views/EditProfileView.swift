import SwiftUI
import PhotosUI
import FirebaseAuth

struct EditProfileView: View {
    @ObservedObject var profileService: ProfileService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var location: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = ""
    @State private var photoURL: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: UIImage?
    @State private var showDatePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let genders = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.05),
                        Color("CleverTapSecondary").opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        profileImageSection
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Name Field
                            CustomTextField(
                                title: "Full Name",
                                text: $name,
                                icon: "person.fill"
                            )
                            
                            // Email and Phone are read-only by requirement
                            ReadOnlyInfoField(
                                title: "Email",
                                value: email,
                                icon: "envelope.fill"
                            )

                            ReadOnlyInfoField(
                                title: "Phone Number",
                                value: phone,
                                icon: "phone.fill"
                            )

                            // Location Field
                            CustomTextField(
                                title: "Location",
                                text: $location,
                                icon: "location.fill"
                            )
                            
                            // Photo URL Field
                            CustomTextField(
                                title: "Photo URL (Optional)",
                                text: $photoURL,
                                icon: "photo.fill",
                                keyboardType: .URL
                            )
                            
                            // Date of Birth Field
                            dateOfBirthField
                            
                            // Gender Field
                            genderField
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        saveButton
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("CleverTapPrimary"))
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadSelectedPhoto(from: newItem)
                }
            }
            .alert("Profile Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                if let selectedPhoto {
                    Image(uiImage: selectedPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let resolvedPhotoURL = resolveImageURL(from: photoURL), !photoURL.isEmpty {
                    AsyncImage(url: resolvedPhotoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        profileInitials
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else if let resolvedProfilePhotoURL = resolveImageURL(from: profileService.userProfile.photoURL), !profileService.userProfile.photoURL.isEmpty {
                    AsyncImage(url: resolvedProfilePhotoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        profileInitials
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    profileInitials
                }
                
                // Upload indicator
                if profileService.isUploadingImage {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 120, height: 120)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            .shadow(color: Color("CleverTapPrimary").opacity(0.3), radius: 10, x: 0, y: 5)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }

            Text("Pick from gallery or use an image URL below")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var profileInitials: some View {
        Text(getInitials())
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.white)
    }
    
    // MARK: - Date of Birth Field
    private var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color("CleverTapPrimary"))
                    .frame(width: 20)
                
                Text("Date of Birth")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Button(action: { showDatePicker.toggle() }) {
                HStack {
                    Text(formatDate(dateOfBirth))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
            
            if showDatePicker {
                DatePicker(
                    "",
                    selection: $dateOfBirth,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDatePicker)
    }
    
    // MARK: - Gender Field
    private var genderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color("CleverTapPrimary"))
                    .frame(width: 20)
                
                Text("Gender")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(genders, id: \.self) { genderOption in
                    Button(action: { gender = genderOption }) {
                        Text(genderOption)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(gender == genderOption ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                gender == genderOption ?
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        gender == genderOption ? .clear : .white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack(spacing: 12) {
                if profileService.isLoading || profileService.isUploadingImage {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                
                Text(profileService.isLoading || profileService.isUploadingImage ? "Saving..." : "Save Changes")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: Color("CleverTapPrimary").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(profileService.isLoading || profileService.isUploadingImage)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentProfile() {
        let profile = profileService.userProfile
        name = profile.name
        email = Auth.auth().currentUser?.email ?? "Not available"
        phone = profile.phone.isEmpty ? "Not set" : profile.phone
        location = profile.location
        dateOfBirth = profile.dateOfBirth ?? Date()
        gender = profile.gender
        photoURL = profile.photoURL
    }
    
    private func saveProfile() {
        let finishProfileUpdate: (String?) -> Void = { updatedPhotoURL in
            profileService.updateUserProfile(
                name: name.isEmpty ? nil : name,
                location: location.isEmpty ? nil : location,
                dateOfBirth: dateOfBirth,
                gender: gender.isEmpty ? nil : gender,
                photoURL: updatedPhotoURL ?? (photoURL.isEmpty ? nil : photoURL)
            ) { success in
                DispatchQueue.main.async {
                    if success {
                        alertMessage = "Profile updated successfully!"
                        showAlert = true

                        CleverTapService.shared.trackScreenViewed(screenName: "Profile Updated")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    } else {
                        alertMessage = "Failed to update profile. Please try again."
                        showAlert = true
                    }
                }
            }
        }

        if let selectedPhoto {
            profileService.updateProfileImage(selectedPhoto) { success, storedURL in
                DispatchQueue.main.async {
                    if success {
                        if let storedURL {
                            self.photoURL = storedURL
                        }
                        finishProfileUpdate(storedURL)
                    } else {
                        alertMessage = "Failed to upload profile image. Please try again."
                        showAlert = true
                    }
                }
            }
        } else {
            finishProfileUpdate(nil)
        }
    }
    
    private func getInitials() -> String {
        let displayName = name.isEmpty ? "User" : name
        let components = displayName.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(displayName.prefix(2)).uppercased()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedPhoto = image
                    photoURL = ""
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to load selected image."
                showAlert = true
            }
        }
    }

    private func resolveImageURL(from value: String) -> URL? {
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }
        return URL(fileURLWithPath: value)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("CleverTapPrimary"))
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            TextField("Enter \(title.lowercased())", text: $text)
                .keyboardType(keyboardType)
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct ReadOnlyInfoField: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("CleverTapPrimary"))
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            HStack {
                Text(value.isEmpty ? "Not set" : value)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    EditProfileView(profileService: ProfileService())
} 
